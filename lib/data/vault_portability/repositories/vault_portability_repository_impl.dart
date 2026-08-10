import 'dart:convert';
import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:flutter/foundation.dart';
import 'package:pass_doc_manager/data/vault_sync/mirror/local_folder_mirror_data_source.dart';
import 'package:pass_doc_manager/data/vault_sync/mirror/vault_mirror_workspace_builder.dart';
import 'package:pass_doc_manager/data/bundles/datasources/local/bundles_local_data_source.dart';
import 'package:pass_doc_manager/data/bundles/dtos/bundle_record_dto.dart';
import 'package:pass_doc_manager/data/collections/datasources/local/collections_local_data_source.dart';
import 'package:pass_doc_manager/data/collections/dtos/collection_record_dto.dart';
import 'package:pass_doc_manager/data/profile/datasources/local/profile_local_data_source.dart';
import 'package:pass_doc_manager/data/tasks/datasources/local/tasks_local_data_source.dart';
import 'package:pass_doc_manager/data/tasks/dtos/task_record_dto.dart';
import 'package:pass_doc_manager/data/profile/dtos/profile_record_dto.dart';
import 'package:pass_doc_manager/data/vault_portability/datasources/local/vault_snapshot_codec.dart';
import 'package:pass_doc_manager/data/vault_portability/datasources/local/vault_store_local_data_source.dart';
import 'package:pass_doc_manager/data/vault_portability/dtos/vault_document_record_dto.dart';
import 'package:pass_doc_manager/data/vault_portability/dtos/vault_password_record_dto.dart';
import 'package:pass_doc_manager/data/vault_portability/dtos/vault_snapshot_dto.dart';
import 'package:pass_doc_manager/data/vault_portability/mappers/vault_portability_mapper.dart';
import 'package:pass_doc_manager/domain/vault_portability/entities/export_vault_request_entity.dart';
import 'package:pass_doc_manager/domain/vault_portability/entities/export_vault_result_entity.dart';
import 'package:pass_doc_manager/domain/vault_portability/entities/export_vault_with_files_request_entity.dart';
import 'package:pass_doc_manager/domain/vault_portability/entities/export_vault_with_files_result_entity.dart';
import 'package:pass_doc_manager/domain/vault_portability/entities/import_merge_strategy.dart';
import 'package:pass_doc_manager/domain/vault_portability/entities/import_vault_request_entity.dart';
import 'package:pass_doc_manager/domain/vault_portability/entities/import_vault_result_entity.dart';
import 'package:pass_doc_manager/domain/vault_portability/entities/portable_data_scope.dart';
import 'package:pass_doc_manager/domain/vault_portability/entities/vault_portability_policy_entity.dart';
import 'package:pass_doc_manager/domain/vault_portability/repositories/vault_portability_repository.dart';

class VaultPortabilityRepositoryImpl implements VaultPortabilityRepository {
  const VaultPortabilityRepositoryImpl({
    required this.localDataSource,
    required this.collectionsLocalDataSource,
    required this.bundlesLocalDataSource,
    required this.tasksLocalDataSource,
    required this.profileLocalDataSource,
    required this.snapshotCodec,
    required this.mirrorBuilder,
    required this.localMirrorDataSource,
  });

  final VaultStoreLocalDataSource localDataSource;
  final CollectionsLocalDataSource collectionsLocalDataSource;
  final BundlesLocalDataSource bundlesLocalDataSource;
  final TasksLocalDataSource tasksLocalDataSource;
  final ProfileLocalDataSource profileLocalDataSource;
  final VaultSnapshotCodec snapshotCodec;
  final VaultMirrorWorkspaceBuilder mirrorBuilder;
  final LocalFolderMirrorDataSource localMirrorDataSource;

  @override
  Future<ExportVaultResultEntity> exportVault(
    ExportVaultRequestEntity request,
  ) async {
    final now = DateTime.now().toUtc();
    final exportedAtIso = now.toIso8601String();

    final snapshot = await _buildExportSnapshot(
      scope: request.scope,
      exportedAtIso: exportedAtIso,
      categoryKeys: request.categoryKeys,
      collectionIds: request.collectionIds,
      includeCredentials: request.includeCredentials,
      includeCollections: request.includeCollections,
    );

    final encryptedPayload = await snapshotCodec.encode(
      snapshot: snapshot,
      passphrase: request.passphrase,
    );

    return ExportVaultResultEntity(
      bundleId: 'vault_${now.millisecondsSinceEpoch}',
      exportedAtIso: exportedAtIso,
      scope: request.scope,
      documentCount: snapshot.documents.length,
      passwordCount: snapshot.passwords.length,
      encryptedPayload: encryptedPayload,
    );
  }

  @override
  Future<ExportVaultWithFilesResultEntity> exportVaultWithFiles(
    ExportVaultWithFilesRequestEntity request,
  ) async {
    final now = DateTime.now().toUtc();
    final exportedAtIso = now.toIso8601String();

    // Build the SAME mirror workspace the backup/sync uses, then zip it, so an
    // export is a clean, browsable Collections/Documents/… tree that restores
    // through the normal mirror import. A throwaway deviceId + a temp folder
    // keep this fully read-only: it never touches the backup chain, the sync
    // journal, or the real mirror.
    _emitProgress(request, 'Building vault mirror...');
    final workspace = await mirrorBuilder.build(deviceId: 'export', revision: 1);
    _log(
      'Mirror built: ${workspace.nodeCount} nodes, ${workspace.fileCount} files',
    );

    _emitProgress(request, 'Writing mirror files...');
    final tempDirectory = await Directory.systemTemp.createTemp(
      'pdm_vault_mirror_',
    );
    final mirrorDirectory = '${tempDirectory.path}/mirror';
    await Directory(mirrorDirectory).create(recursive: true);
    await localMirrorDataSource.writeWorkspace(
      folderPath: mirrorDirectory,
      workspace: workspace,
    );

    final archiveFileName = _readableArchiveFileName(now);
    final archivePath = '${tempDirectory.path}/$archiveFileName';

    _emitProgress(request, 'Packaging archive...', progress: 0.9);
    final zipEncoder = ZipFileEncoder();
    zipEncoder.create(archivePath, level: ZipFileEncoder.store);
    await zipEncoder.addDirectory(
      Directory(mirrorDirectory),
      includeDirName: false,
    );
    await zipEncoder.close();

    // Remove the unzipped plaintext mirror copy; keep only the .zip.
    try {
      await Directory(mirrorDirectory).delete(recursive: true);
    } catch (_) {
      // Best-effort cleanup.
    }

    if (!await File(archivePath).exists()) {
      throw const FormatException('Unable to encode vault archive.');
    }
    _emitProgress(request, 'Archive ready.', progress: 1);
    _log('Archive ready at $archivePath');

    final documents = workspace.snapshot['documents'];
    final credentials = workspace.snapshot['credentials'];
    return ExportVaultWithFilesResultEntity(
      bundleId: 'vault_${now.millisecondsSinceEpoch}',
      exportedAtIso: exportedAtIso,
      scope: request.scope,
      documentCount: documents is List ? documents.length : 0,
      passwordCount: credentials is List ? credentials.length : 0,
      fileCount: workspace.fileCount,
      archiveFileName: archiveFileName,
      archiveFilePath: archivePath,
    );
  }

  @override
  Future<ImportVaultResultEntity> importVault(
    ImportVaultRequestEntity request,
  ) async {
    final snapshot = await snapshotCodec.decode(
      encryptedPayload: request.encryptedPayload,
      passphrase: request.passphrase,
    );

    final result = await localDataSource.applySnapshot(
      snapshot: snapshot,
      strategy: request.strategy,
    );
    await _applyCollectionsSnapshot(
      rawCollections: snapshot.collections,
      strategy: request.strategy,
    );
    await _applyBundlesSnapshot(
      rawBundles: snapshot.bundles,
      strategy: request.strategy,
    );
    await _applyTasksSnapshot(
      rawTaskLists: snapshot.tasks,
      strategy: request.strategy,
    );

    if (snapshot.profile != null) {
      final profileDto = ProfileRecordDto.fromMap(snapshot.profile!);
      await profileLocalDataSource.writeProfile(profileDto);
    }

    return result.toEntity();
  }

  @override
  Future<VaultPortabilityPolicyEntity> getPortabilityPolicy() async {
    return const VaultPortabilityPolicyEntity(
      canImportAtAnyTime: true,
      canExportAtAnyTime: true,
    );
  }

  Future<VaultSnapshotDto> _buildExportSnapshot({
    required PortableDataScope scope,
    required String exportedAtIso,
    required List<String> categoryKeys,
    required List<String> collectionIds,
    required bool includeCredentials,
    required bool includeCollections,
  }) async {
    final baseSnapshot = await localDataSource.createSnapshot(
      scope: scope,
      exportedAtIso: exportedAtIso,
    );

    final selectedCategoryKeys = _normalizeStringSet(categoryKeys);
    final selectedCollectionIds = _normalizeStringSet(collectionIds);

    final collections = includeCollections
        ? await _loadFilteredCollections(selectedCollectionIds)
        : const <CollectionRecordDto>[];

    final linkedDocumentIds = _extractLinkedDocumentIds(collections);
    final filteredDocuments = selectExportDocuments(
      documents: baseSnapshot.documents,
      selectedCategoryKeys: selectedCategoryKeys,
      selectedCollectionIds: selectedCollectionIds,
      linkedDocumentIds: linkedDocumentIds,
    );

    final filteredPasswords = includeCredentials
        ? baseSnapshot.passwords
        : const <VaultPasswordRecordDto>[];

    final profileDto = await profileLocalDataSource.readProfile();

    // Bundles + Tasks are carried verbatim: they only hold ID references to
    // other vault items, and have no asset files of their own, so the map
    // serialisation from their record DTOs is sufficient for round-tripping.
    final bundles = await bundlesLocalDataSource.getBundles();
    final taskLists = await tasksLocalDataSource.getTaskLists();

    return VaultSnapshotDto(
      exportedAtIso: baseSnapshot.exportedAtIso,
      documents: filteredDocuments,
      passwords: filteredPasswords,
      collections: collections
          .map((item) => item.toMap())
          .toList(growable: false),
      bundles: bundles.map((item) => item.toMap()).toList(growable: false),
      tasks: taskLists.map((item) => item.toMap()).toList(growable: false),
      profile: profileDto.toMap(),
    );
  }

  Set<String> _normalizeStringSet(List<String> values) {
    return values
        .map((item) => item.trim().toLowerCase())
        .where((item) => item.isNotEmpty)
        .toSet();
  }

  Future<List<CollectionRecordDto>> _loadFilteredCollections(
    Set<String> selectedCollectionIds,
  ) async {
    final all = await collectionsLocalDataSource.getCollections();
    if (selectedCollectionIds.isEmpty) {
      return all;
    }
    return all
        .where((item) => selectedCollectionIds.contains(item.id.toLowerCase()))
        .toList(growable: false);
  }


  Set<String> _extractLinkedDocumentIds(List<CollectionRecordDto> collections) {
    final documentIds = <String>{};
    for (final collection in collections) {
      for (final block in collection.blocks) {
        for (final entry in block.metadata.entries) {
          final normalizedKey = entry.key.trim().toLowerCase().replaceAll(
            ' ',
            '_',
          );
          if (!_isDocumentLinkMetadataKey(normalizedKey)) {
            continue;
          }
          final values = _extractDocumentIdValues(entry.value);
          documentIds.addAll(values);
        }
      }
    }
    return documentIds;
  }

  bool _isDocumentLinkMetadataKey(String normalizedKey) {
    if (_documentLinkMetadataKeys.contains(normalizedKey)) {
      return true;
    }
    return normalizedKey.contains('document') &&
        (normalizedKey.contains('id') || normalizedKey.endsWith('_ids'));
  }

  Set<String> _extractDocumentIdValues(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) {
      return const <String>{};
    }

    final values = <String>{};
    if (trimmed.startsWith('[') && trimmed.endsWith(']')) {
      try {
        final decoded = jsonDecode(trimmed);
        if (decoded is List) {
          for (final item in decoded) {
            final value = '$item'.trim();
            if (value.isNotEmpty) {
              values.add(value);
            }
          }
          return values;
        }
      } catch (_) {
        // Expected: input may not be valid JSON — fall through to split logic.
      }
    }

    for (final token in trimmed.split(RegExp(r'[,;|]'))) {
      final value = token.trim();
      if (value.isNotEmpty) {
        values.add(value);
      }
    }
    if (values.isNotEmpty) {
      return values;
    }
    return <String>{trimmed};
  }

  Future<void> _applyCollectionsSnapshot({
    required List<Map<String, dynamic>> rawCollections,
    required ImportMergeStrategy strategy,
  }) async {
    final incoming = rawCollections
        .map(CollectionRecordDto.fromMap)
        .where((item) => item.id.trim().isNotEmpty)
        .toList(growable: false);

    if (strategy == ImportMergeStrategy.replace) {
      await collectionsLocalDataSource.saveCollections(incoming);
      return;
    }

    if (incoming.isEmpty) {
      return;
    }

    final existing = await collectionsLocalDataSource.getCollections();
    final mergedById = <String, CollectionRecordDto>{
      for (final item in existing) item.id: item,
    };
    for (final item in incoming) {
      mergedById[item.id] = item;
    }
    final merged = mergedById.values.toList(growable: false)
      ..sort((a, b) => b.updatedAtIso.compareTo(a.updatedAtIso));
    await collectionsLocalDataSource.saveCollections(merged);
  }

  Future<void> _applyBundlesSnapshot({
    required List<Map<String, dynamic>> rawBundles,
    required ImportMergeStrategy strategy,
  }) async {
    final incoming = rawBundles
        .map(BundleRecordDto.fromMap)
        .where((item) => item.id.trim().isNotEmpty)
        .toList(growable: false);

    if (strategy == ImportMergeStrategy.replace) {
      await bundlesLocalDataSource.saveBundles(incoming);
      return;
    }
    if (incoming.isEmpty) return;

    final existing = await bundlesLocalDataSource.getBundles();
    final mergedById = <String, BundleRecordDto>{
      for (final item in existing) item.id: item,
    };
    for (final item in incoming) {
      mergedById[item.id] = item;
    }
    final merged = mergedById.values.toList(growable: false)
      ..sort((a, b) => b.updatedAtIso.compareTo(a.updatedAtIso));
    await bundlesLocalDataSource.saveBundles(merged);
  }

  Future<void> _applyTasksSnapshot({
    required List<Map<String, dynamic>> rawTaskLists,
    required ImportMergeStrategy strategy,
  }) async {
    final incoming = rawTaskLists
        .map(TaskListRecordDto.fromMap)
        .where((item) => item.id.trim().isNotEmpty)
        .toList(growable: false);

    if (strategy == ImportMergeStrategy.replace) {
      await tasksLocalDataSource.saveTaskLists(incoming);
      return;
    }
    if (incoming.isEmpty) return;

    final existing = await tasksLocalDataSource.getTaskLists();
    final mergedById = <String, TaskListRecordDto>{
      for (final item in existing) item.id: item,
    };
    for (final item in incoming) {
      mergedById[item.id] = item;
    }
    final merged = mergedById.values.toList(growable: false)
      ..sort((a, b) => b.updatedAtIso.compareTo(a.updatedAtIso));
    await tasksLocalDataSource.saveTaskLists(merged);
  }

  void _emitProgress(
    ExportVaultWithFilesRequestEntity request,
    String message, {
    double? progress,
  }) {
    request.onProgress?.call(message, progress);
    _log(message, progress: progress);
  }

  void _log(String message, {double? progress}) {
    final suffix = progress == null
        ? ''
        : ' (${(progress * 100).toStringAsFixed(0)}%)';
    stdout.writeln('[VaultExport] $message$suffix');
  }

  String _readableArchiveFileName(DateTime now) {
    final local = now.toLocal();
    String two(int v) => v.toString().padLeft(2, '0');
    final stamp =
        '${local.year}-${two(local.month)}-${two(local.day)}-'
        '${two(local.hour)}${two(local.minute)}';
    return 'Credence-Vault-$stamp.zip';
  }

}


/// Chooses which documents an export includes.
///
/// With **no** category or specific-collection filter selected, this is a FULL
/// export and every document is returned. When a filter IS selected, documents
/// are kept if they match a chosen category OR are referenced (linked) by a
/// chosen collection — so collection links only ever *broaden* a filtered set,
/// never restrict a full export.
@visibleForTesting
List<VaultDocumentRecordDto> selectExportDocuments({
  required List<VaultDocumentRecordDto> documents,
  required Set<String> selectedCategoryKeys,
  required Set<String> selectedCollectionIds,
  required Set<String> linkedDocumentIds,
}) {
  final hasExplicitFilter =
      selectedCategoryKeys.isNotEmpty || selectedCollectionIds.isNotEmpty;
  if (!hasExplicitFilter) {
    return documents;
  }
  return documents
      .where(
        (item) =>
            selectedCategoryKeys.contains(item.category.trim().toLowerCase()) ||
            linkedDocumentIds.contains(item.id.trim()),
      )
      .toList(growable: false);
}

const Set<String> _documentLinkMetadataKeys = <String>{
  'document_id',
  'document_ids',
  'source_document_id',
  'source_document_ids',
  'vault_document_id',
  'vault_document_ids',
  'linked_document_id',
  'linked_document_ids',
  'attached_document_id',
  'attached_document_ids',
};

