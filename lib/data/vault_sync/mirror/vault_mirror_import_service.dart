import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';

import 'package:cryptography/cryptography.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pass_doc_manager/core/utils/local_asset_path_resolver.dart';
import 'package:pass_doc_manager/data/bundles/datasources/local/bundles_local_data_source.dart';
import 'package:pass_doc_manager/data/bundles/dtos/bundle_record_dto.dart';
import 'package:pass_doc_manager/data/collections/datasources/local/collections_local_data_source.dart';
import 'package:pass_doc_manager/data/collections/dtos/collection_record_dto.dart';
import 'package:pass_doc_manager/data/credentials/datasources/local/credential_local_data_source.dart';
import 'package:pass_doc_manager/data/documents/datasources/local/document_local_data_source.dart';
import 'package:pass_doc_manager/data/documents/dtos/document_record_dto.dart';
import 'package:pass_doc_manager/data/notes/datasources/local/secure_notes_local_data_source.dart';
import 'package:pass_doc_manager/data/profile/datasources/local/profile_local_data_source.dart';
import 'package:pass_doc_manager/data/profile/dtos/profile_record_dto.dart';
import 'package:pass_doc_manager/data/tasks/datasources/local/tasks_local_data_source.dart';
import 'package:pass_doc_manager/data/tasks/dtos/task_record_dto.dart';
import 'package:pass_doc_manager/data/vault_sync/mirror/vault_mirror_import_source.dart';
import 'package:pass_doc_manager/data/vault_sync/mirror/vault_mirror_workspace.dart';
import 'package:pass_doc_manager/domain/vault_sync/entities/vault_sync_progress_entity.dart';

enum VaultMirrorImportMode { replace, merge }

class VaultMirrorImportService {
  const VaultMirrorImportService({
    required this.documentLocalDataSource,
    required this.collectionsLocalDataSource,
    required this.bundlesLocalDataSource,
    required this.tasksLocalDataSource,
    required this.credentialLocalDataSource,
    required this.profileLocalDataSource,
    required this.secureNotesLocalDataSource,
  });

  final DocumentLocalDataSource documentLocalDataSource;
  final CollectionsLocalDataSource collectionsLocalDataSource;
  final BundlesLocalDataSource bundlesLocalDataSource;
  final TasksLocalDataSource tasksLocalDataSource;
  final CredentialLocalDataSource credentialLocalDataSource;
  final ProfileLocalDataSource profileLocalDataSource;
  final SecureNotesLocalDataSource secureNotesLocalDataSource;

  Future<VaultMirrorResult> importFromSource({
    required VaultMirrorImportSource source,
    VaultMirrorImportMode mode = VaultMirrorImportMode.replace,
    VaultSyncProgressCallback? onProgress,
  }) async {
    await LocalAssetPathResolver.initialize();
    _emitProgress(
      onProgress,
      message: 'Reading mirror manifest',
      detail: 'Loading structure and checksums from ${source.label}.',
      progress: 0.04,
    );
    final manifestText = await source.readText(
      VaultMirrorWorkspace.manifestPath,
    );
    final manifest = VaultMirrorManifest.fromJsonText(manifestText);
    final contentIndex = _contentIndexFromManifestText(manifestText);
    final contentPayloadIndex = _contentPayloadIndexFromManifestText(
      manifestText,
    );
    final snapshotText = await source.readText(
      VaultMirrorWorkspace.snapshotPath,
    );

    await _validateInlineFile(
      relativePath: VaultMirrorWorkspace.snapshotPath,
      content: utf8.encode(snapshotText),
      manifest: manifest,
    );

    _emitProgress(
      onProgress,
      message: 'Restoring mirror files',
      detail: 'Copying referenced files and images back to local storage.',
      progress: 0.12,
      totalCount: manifest.filesByPath.length,
    );
    final fileRestore = await _restoreMirrorFiles(
      source: source,
      manifest: manifest,
      onProgress: onProgress,
    );
    final pathMapping = fileRestore.pathMapping;

    _emitProgress(
      onProgress,
      message: 'Rewriting local paths',
      detail: 'Relinking documents, images, icons, notes, and metadata.',
      progress: 0.70,
    );
    final rawSnapshot = jsonDecode(snapshotText);
    if (rawSnapshot is! Map) {
      throw StateError('Mirror snapshot is not a JSON object.');
    }
    final rewriteEntries = _sortedRewriteEntries(pathMapping);
    final snapshot =
        _rewriteObject(
              Map<String, dynamic>.from(rawSnapshot),
              pathMapping,
              rewriteEntries,
            )
            as Map<String, dynamic>;
    final pathAudit = _auditRestoredLocalPaths(snapshot);
    if (pathAudit.hasMissingPaths) {
      final firstMissing = pathAudit.samples.isEmpty
          ? 'No sample available.'
          : pathAudit.samples.first;
      debugPrint(
        '[VaultMirrorImport] Continuing restore with '
        '${pathAudit.missingCount} unavailable legacy file reference(s). '
        'First missing path: $firstMissing',
      );
      _emitProgress(
        onProgress,
        message: 'Restoring available data',
        detail:
            'Vault records will be restored. ${pathAudit.missingCount} legacy file reference(s) were unavailable.',
        progress: 0.74,
      );
    }

    _emitProgress(
      onProgress,
      message: 'Restoring vault records',
      detail: mode == VaultMirrorImportMode.merge
          ? 'Merging mirrored records with local additions.'
          : 'Replacing local records with the mirrored workspace.',
      progress: 0.78,
    );
    await _restoreSnapshot(snapshot, mode: mode);
    await _verifyCollectionRestore(snapshot: snapshot, mode: mode);

    final checksum = manifest.contentChecksum.isNotEmpty
        ? manifest.contentChecksum
        : await _hashBytes(utf8.encode(manifestText));
    final missingReferenceCount =
        pathAudit.missingCount + fileRestore.failedFiles.length;
    final warningMessage = missingReferenceCount == 0
        ? null
        : '${_countLabel(missingReferenceCount, 'legacy file reference')} could not be restored. Vault records were recovered.';
    _emitProgress(
      onProgress,
      message: 'Restore complete',
      detail:
          warningMessage ??
          'Imported ${fileRestore.restoredCount} files and ${manifest.managedDirectories.length} folders.',
      progress: 1,
      processedCount: fileRestore.restoredCount,
      totalCount: manifest.filesByPath.length,
      fileCount: fileRestore.restoredCount,
    );

    return VaultMirrorResult(
      revision: manifest.revision,
      fileCount: fileRestore.restoredCount,
      directoryCount: manifest.managedDirectories.length,
      entityCount:
          _asList(snapshot['documents']).length +
          _asList(snapshot['collections']).length +
          _asList(snapshot['bundles']).length +
          _asList(snapshot['tasks']).length +
          _asList(snapshot['credentials']).length +
          _asList(snapshot['secure_notes']).length,
      byteCount: fileRestore.restoredBytes,
      checksum: checksum,
      manifestPath: source.label,
      contentIndex: contentIndex,
      contentPayloadIndex: contentPayloadIndex,
      warningMessage: warningMessage,
    );
  }

  Future<_MirrorFileRestoreResult> _restoreMirrorFiles({
    required VaultMirrorImportSource source,
    required VaultMirrorManifest manifest,
    VaultSyncProgressCallback? onProgress,
  }) async {
    final appSupport = await getApplicationSupportDirectory();
    final root = Directory('${appSupport.path}/vault_mirror_restored');
    await root.create(recursive: true);

    final mapping = <String, String>{};
    final failedFiles = <String>[];
    var restoredCount = 0;
    var restoredBytes = 0;
    final files = manifest.filesByPath.values
        .where((file) => _shouldRestoreMirrorFile(file.path))
        .toList(growable: false);
    for (var i = 0; i < files.length; i++) {
      final file = files[i];
      _emitProgress(
        onProgress,
        message: 'Restoring mirror files',
        detail: 'Copying ${file.path}.',
        progress: _mapProgress(i, files.length, 0.12, 0.68),
        processedCount: i,
        totalCount: files.length,
        fileCount: files.length,
      );
      final finalDestination = File(_safeDestination(root, file.path));
      await finalDestination.parent.create(recursive: true);
      try {
        final isAlreadyRestored = await _fileMatchesHash(
          finalDestination,
          file.sha256,
        );
        if (!isAlreadyRestored) {
          await _downloadAndReplaceMirrorFile(
            source: source,
            relativePath: file.path,
            destination: finalDestination,
            expectedHash: file.sha256,
          );
        }
        _addPathMapping(mapping, file.path, finalDestination.path);
        final sourcePath = file.sourcePath?.trim();
        if (sourcePath != null && sourcePath.isNotEmpty) {
          _addPathMapping(mapping, sourcePath, finalDestination.path);
        }
        restoredCount += 1;
        restoredBytes += file.sizeBytes;
      } catch (error, stackTrace) {
        try {
          final partial = File('${finalDestination.path}.download');
          if (partial.existsSync()) {
            await partial.delete();
          }
        } catch (_) {}
        failedFiles.add(file.path);
        developer.log(
          '[VaultMirrorImport] Could not restore mirror file ${file.path}: $error',
          name: 'VaultMirrorImport',
          error: error,
          stackTrace: stackTrace,
        );
      }
    }
    developer.log(
      '[VaultMirrorImport] Restored $restoredCount/${files.length} mirror files to '
      '${root.path} with ${mapping.length} path aliases.',
      name: 'VaultMirrorImport',
    );
    debugPrint(
      '[VaultMirrorImport] Restored $restoredCount/${files.length} mirror files to '
      '${root.path} with ${mapping.length} path aliases.',
    );
    if (failedFiles.isNotEmpty) {
      debugPrint(
        '[VaultMirrorImport] ${failedFiles.length} mirrored file(s) were unavailable.',
      );
    }
    return _MirrorFileRestoreResult(
      pathMapping: mapping,
      failedFiles: List<String>.unmodifiable(failedFiles),
      restoredCount: restoredCount,
      restoredBytes: restoredBytes,
    );
  }

  bool _shouldRestoreMirrorFile(String rawPath) {
    // The manifest and snapshot (in either the current or legacy metadata dir)
    // are consumed directly, never restored as content files.
    return !VaultMirrorWorkspace.isReservedMetadataFile(rawPath);
  }

  Future<void> _restoreSnapshot(
    Map<String, dynamic> snapshot, {
    required VaultMirrorImportMode mode,
  }) async {
    if (mode == VaultMirrorImportMode.merge) {
      await _mergeSnapshot(snapshot);
      return;
    }

    final documentsRaw = snapshot['documents'];
    if (documentsRaw is List) {
      await documentLocalDataSource.replaceDocuments(
        documentsRaw
            .whereType<Map>()
            .map(
              (item) =>
                  DocumentRecordDto.fromMap(Map<String, dynamic>.from(item)),
            )
            .toList(growable: false),
      );
    }

    final collectionsRaw = snapshot['collections'];
    if (collectionsRaw is List) {
      await collectionsLocalDataSource.saveCollections(
        collectionsRaw
            .whereType<Map>()
            .map(
              (item) =>
                  CollectionRecordDto.fromMap(Map<String, dynamic>.from(item)),
            )
            .toList(growable: false),
      );
    }

    final bundlesRaw = snapshot['bundles'];
    if (bundlesRaw is List) {
      await bundlesLocalDataSource.saveBundles(
        bundlesRaw
            .whereType<Map>()
            .map(
              (item) =>
                  BundleRecordDto.fromMap(Map<String, dynamic>.from(item)),
            )
            .toList(growable: false),
      );
    }

    final tasksRaw = snapshot['tasks'];
    if (tasksRaw is List) {
      await tasksLocalDataSource.saveTaskLists(
        tasksRaw
            .whereType<Map>()
            .map(
              (item) =>
                  TaskListRecordDto.fromMap(Map<String, dynamic>.from(item)),
            )
            .toList(growable: false),
      );
    }

    final profileRaw = snapshot['profile'];
    if (profileRaw is Map) {
      await profileLocalDataSource.writeProfile(
        ProfileRecordDto.fromMap(Map<String, dynamic>.from(profileRaw)),
      );
    }

    final credentialsRaw = snapshot['credentials'];
    if (credentialsRaw is List) {
      await credentialLocalDataSource.replaceCredentialRows(
        credentialsRaw
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList(growable: false),
      );
    }

    final secureNotesRaw = snapshot['secure_notes'];
    if (secureNotesRaw is List) {
      await secureNotesLocalDataSource.replaceNoteSnapshots(
        secureNotesRaw
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList(growable: false),
      );
    }
  }

  Future<void> _verifyCollectionRestore({
    required Map<String, dynamic> snapshot,
    required VaultMirrorImportMode mode,
  }) async {
    final expected = _parseRecordList<CollectionRecordDto>(
      snapshot['collections'],
      CollectionRecordDto.fromMap,
    ).where((item) => item.id.trim().isNotEmpty).toList(growable: false);
    if (expected.isEmpty) {
      return;
    }
    final restored = await collectionsLocalDataSource.getCollections();
    final restoredIds = {
      for (final collection in restored) collection.id.trim(),
    };
    final missing = expected
        .where((collection) => !restoredIds.contains(collection.id.trim()))
        .toList(growable: false);
    if (missing.isNotEmpty) {
      final firstMissing = missing.first.name.trim().isEmpty
          ? missing.first.id
          : missing.first.name;
      throw StateError(
        'Mirror restore could not make ${missing.length} of ${expected.length} collection records available. First missing collection: $firstMissing.',
      );
    }
    debugPrint(
      '[VaultMirrorImport] Verified ${expected.length} mirrored collection record(s) after ${mode.name} restore.',
    );
  }

  Future<void> _mergeSnapshot(Map<String, dynamic> snapshot) async {
    // Deletions another device recorded travel in `snapshot['tombstones']`.
    // A merge honors them so a record deleted elsewhere does not resurrect
    // here. Absent the field (older snapshots) every map is empty → no-op.
    final tombstones = parseSnapshotTombstones(snapshot['tombstones']);

    final incomingDocuments = _parseRecordList<DocumentRecordDto>(
      snapshot['documents'],
      DocumentRecordDto.fromMap,
    );
    final documentTombstones = tombstones['document'] ?? const {};
    if (incomingDocuments.isNotEmpty || documentTombstones.isNotEmpty) {
      final existingDocuments = await documentLocalDataSource.getDocuments();
      await documentLocalDataSource.replaceDocuments(
        _mergeById<DocumentRecordDto>(
          existing: existingDocuments,
          incoming: incomingDocuments,
          idOf: (item) => item.id,
          updatedAtOf: (item) => item.updatedAtIso,
          tombstoneDeletedAtById: documentTombstones,
        ),
      );
    }

    final incomingCollections = _parseRecordList<CollectionRecordDto>(
      snapshot['collections'],
      CollectionRecordDto.fromMap,
    );
    final collectionTombstones = tombstones['collection'] ?? const {};
    if (incomingCollections.isNotEmpty || collectionTombstones.isNotEmpty) {
      final existingCollections = await collectionsLocalDataSource
          .getCollections();
      await collectionsLocalDataSource.saveCollections(
        _mergeById<CollectionRecordDto>(
          existing: existingCollections,
          incoming: incomingCollections,
          idOf: (item) => item.id,
          updatedAtOf: (item) => item.updatedAtIso,
          tombstoneDeletedAtById: collectionTombstones,
        ),
      );
    }

    final incomingBundles = _parseRecordList<BundleRecordDto>(
      snapshot['bundles'],
      BundleRecordDto.fromMap,
    );
    final bundleTombstones = tombstones['bundle'] ?? const {};
    if (incomingBundles.isNotEmpty || bundleTombstones.isNotEmpty) {
      final existingBundles = await bundlesLocalDataSource.getBundles();
      await bundlesLocalDataSource.saveBundles(
        _mergeById<BundleRecordDto>(
          existing: existingBundles,
          incoming: incomingBundles,
          idOf: (item) => item.id,
          updatedAtOf: (item) => item.updatedAtIso,
          tombstoneDeletedAtById: bundleTombstones,
        ),
      );
    }

    final incomingTasks = _parseRecordList<TaskListRecordDto>(
      snapshot['tasks'],
      TaskListRecordDto.fromMap,
    );
    final taskTombstones = tombstones['task_list'] ?? const {};
    if (incomingTasks.isNotEmpty || taskTombstones.isNotEmpty) {
      final existingTasks = await tasksLocalDataSource.getTaskLists();
      await tasksLocalDataSource.saveTaskLists(
        _mergeById<TaskListRecordDto>(
          existing: existingTasks,
          incoming: incomingTasks,
          idOf: (item) => item.id,
          updatedAtOf: (item) => item.updatedAtIso,
          tombstoneDeletedAtById: taskTombstones,
        ),
      );
    }

    final profileRaw = snapshot['profile'];
    if (profileRaw is Map) {
      final incomingProfile = ProfileRecordDto.fromMap(
        Map<String, dynamic>.from(profileRaw),
      );
      final existingProfile = await profileLocalDataSource.readProfile();
      if (_shouldRestoreIncomingProfile(incomingProfile, existingProfile)) {
        await profileLocalDataSource.writeProfile(incomingProfile);
      }
    }

    final incomingCredentials = _rawMaps(
      snapshot['credentials'],
    ).where((item) => _mapId(item).isNotEmpty).toList(growable: false);
    if (incomingCredentials.isNotEmpty) {
      final existingCredentials = await credentialLocalDataSource
          .readCredentialRows();
      await credentialLocalDataSource.replaceCredentialRows(
        _mergeMapsById(
          existing: existingCredentials,
          incoming: incomingCredentials,
          updatedAtKeys: const ['updatedAtIso', 'lastUsedAtIso'],
        ),
      );
    }

    final incomingNotes = _rawMaps(snapshot['secure_notes'])
        .where((item) => _secureNoteSnapshotId(item).isNotEmpty)
        .toList(growable: false);
    if (incomingNotes.isNotEmpty) {
      final existingNotes =
          (await secureNotesLocalDataSource.getAllNoteDetails())
              .map((item) => Map<String, dynamic>.from(item.toMap()))
              .toList(growable: false);
      await secureNotesLocalDataSource.replaceNoteSnapshots(
        _mergeSecureNoteSnapshots(
          existing: existingNotes,
          incoming: incomingNotes,
        ),
      );
    }
  }

  List<T> _parseRecordList<T>(
    Object? raw,
    T Function(Map<String, dynamic> map) fromMap,
  ) {
    return _rawMaps(raw).map(fromMap).toList(growable: false);
  }

  List<Map<String, dynamic>> _rawMaps(Object? raw) {
    if (raw is! List) {
      return const <Map<String, dynamic>>[];
    }
    return raw
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList(growable: false);
  }

  List<T> _mergeById<T>({
    required List<T> existing,
    required List<T> incoming,
    required String Function(T item) idOf,
    required String? Function(T item) updatedAtOf,
    Map<String, String> tombstoneDeletedAtById = const <String, String>{},
  }) {
    final merged = <String, T>{
      for (final item in existing)
        if (idOf(item).trim().isNotEmpty) idOf(item).trim(): item,
    };
    for (final item in incoming) {
      final id = idOf(item).trim();
      if (id.isEmpty) {
        continue;
      }
      final current = merged[id];
      if (current == null ||
          _shouldPreferIncoming(updatedAtOf(item), updatedAtOf(current))) {
        merged[id] = item;
      }
    }
    // Honor deletions: a record another device tombstoned is removed, UNLESS
    // the surviving record was edited strictly after the deletion (edit wins
    // over delete). Because every writer is a full authoritative overwrite,
    // dropping the id from `merged` deletes it locally.
    tombstoneDeletedAtById.forEach((rawId, deletedAtRaw) {
      final id = rawId.trim();
      final current = merged[id];
      if (id.isEmpty || current == null) {
        return;
      }
      if (!mergeTombstoneWins(deletedAtRaw, updatedAtOf(current))) {
        return;
      }
      merged.remove(id);
    });
    return merged.values.toList(growable: false);
  }

  List<Map<String, dynamic>> _mergeMapsById({
    required List<Map<String, dynamic>> existing,
    required List<Map<String, dynamic>> incoming,
    required List<String> updatedAtKeys,
  }) {
    final merged = <String, Map<String, dynamic>>{
      for (final item in existing)
        if (_mapId(item).isNotEmpty) _mapId(item): item,
    };
    for (final item in incoming) {
      final id = _mapId(item);
      if (id.isEmpty) {
        continue;
      }
      final current = merged[id];
      if (current == null ||
          _shouldPreferIncoming(
            _firstMapValue(item, updatedAtKeys),
            _firstMapValue(current, updatedAtKeys),
          )) {
        merged[id] = item;
      }
    }
    return merged.values.toList(growable: false);
  }

  List<Map<String, dynamic>> _mergeSecureNoteSnapshots({
    required List<Map<String, dynamic>> existing,
    required List<Map<String, dynamic>> incoming,
  }) {
    final merged = <String, Map<String, dynamic>>{
      for (final item in existing)
        if (_secureNoteSnapshotId(item).isNotEmpty)
          _secureNoteSnapshotId(item): item,
    };
    for (final item in incoming) {
      final id = _secureNoteSnapshotId(item);
      if (id.isEmpty) {
        continue;
      }
      final current = merged[id];
      if (current == null ||
          _shouldPreferIncoming(
            _secureNoteUpdatedAt(item),
            _secureNoteUpdatedAt(current),
          )) {
        merged[id] = item;
      }
    }
    return merged.values.toList(growable: false);
  }

  bool _shouldPreferIncoming(String? incomingRaw, String? existingRaw) =>
      mergePrefersIncomingByTimestamp(incomingRaw, existingRaw);

  bool _shouldRestoreIncomingProfile(
    ProfileRecordDto incoming,
    ProfileRecordDto existing,
  ) {
    final incomingHasContent = _profileHasUserContent(incoming);
    final existingHasContent = _profileHasUserContent(existing);
    if (incomingHasContent && !existingHasContent) {
      return true;
    }
    if (!incomingHasContent && existingHasContent) {
      return false;
    }
    return _shouldPreferIncoming(incoming.updatedAtIso, existing.updatedAtIso);
  }

  bool _profileHasUserContent(ProfileRecordDto profile) {
    return profile.firstName.trim().isNotEmpty ||
        profile.lastName.trim().isNotEmpty ||
        profile.email.trim().isNotEmpty ||
        profile.phone.trim().isNotEmpty ||
        profile.address.trim().isNotEmpty ||
        profile.socialLinks.trim().isNotEmpty ||
        profile.photoPath.trim().isNotEmpty;
  }

  Map<String, String> _contentIndexFromManifestText(String manifestText) {
    try {
      final decoded = jsonDecode(manifestText);
      if (decoded is! Map) {
        return const <String, String>{};
      }
      final manifest = Map<String, dynamic>.from(decoded);
      final index = <String, String>{};

      final nodes = manifest['nodes'];
      if (nodes is List) {
        for (final rawNode in nodes.whereType<Map>()) {
          final node = Map<String, dynamic>.from(rawNode);
          final id = '${node['id'] ?? ''}'.trim();
          final type = '${node['type'] ?? ''}'.trim();
          final contentHash = '${node['content_hash'] ?? ''}'.trim();
          final metadataHash = '${node['metadata_hash'] ?? ''}'.trim();
          if (id.isEmpty ||
              type.isEmpty ||
              contentHash.isEmpty ||
              metadataHash.isEmpty) {
            continue;
          }
          index['node:$type:$id'] = '$contentHash:$metadataHash';
        }
      }

      final files = manifest['files'];
      if (files is List) {
        for (final rawFile in files.whereType<Map>()) {
          final file = Map<String, dynamic>.from(rawFile);
          final path = '${file['path'] ?? ''}'.trim();
          final sha256 = '${file['sha256'] ?? ''}'.trim();
          if (path.isEmpty ||
              sha256.isEmpty ||
              !_isUserVisibleMirrorFilePath(path)) {
            continue;
          }
          final identityKey = '${file['identity_key'] ?? ''}'.trim();
          final identity = identityKey.isNotEmpty ? identityKey : 'path:$path';
          index['file:$identity'] =
              'v2|path=${Uri.encodeComponent(path)}|sha256=$sha256';
        }
      }

      return Map<String, String>.unmodifiable(index);
    } catch (_) {
      return const <String, String>{};
    }
  }

  Map<String, Map<String, dynamic>> _contentPayloadIndexFromManifestText(
    String manifestText,
  ) {
    try {
      final decoded = jsonDecode(manifestText);
      if (decoded is! Map) {
        return const <String, Map<String, dynamic>>{};
      }
      final manifest = Map<String, dynamic>.from(decoded);
      final index = <String, Map<String, dynamic>>{};

      final nodes = manifest['nodes'];
      if (nodes is List) {
        for (final rawNode in nodes.whereType<Map>()) {
          final node = Map<String, dynamic>.from(rawNode);
          final id = '${node['id'] ?? ''}'.trim();
          final type = '${node['type'] ?? ''}'.trim();
          if (id.isEmpty || type.isEmpty) {
            continue;
          }
          index['node:$type:$id'] = node;
        }
      }

      final files = manifest['files'];
      if (files is List) {
        for (final rawFile in files.whereType<Map>()) {
          final file = Map<String, dynamic>.from(rawFile);
          final path = '${file['path'] ?? ''}'.trim();
          if (path.isEmpty || !_isUserVisibleMirrorFilePath(path)) {
            continue;
          }
          final identityKey = '${file['identity_key'] ?? ''}'.trim();
          final identity = identityKey.isNotEmpty ? identityKey : 'path:$path';
          index['file:$identity'] = {
            'path': path,
            'sha256': '${file['sha256'] ?? ''}'.trim(),
            'size_bytes': file['size_bytes'] ?? 0,
            'identity_key': identity,
          };
        }
      }

      return Map<String, Map<String, dynamic>>.unmodifiable(index);
    } catch (_) {
      return const <String, Map<String, dynamic>>{};
    }
  }

  bool _isUserVisibleMirrorFilePath(String rawPath) {
    final path = rawPath.trim();
    if (path.isEmpty) {
      return false;
    }
    return VaultMirrorWorkspace.isUserVisibleMirrorPath(path);
  }


  String _mapId(Map<String, dynamic> map) {
    return '${map['id'] ?? ''}'.trim();
  }

  String? _firstMapValue(Map<String, dynamic> map, List<String> keys) {
    for (final key in keys) {
      final value = '${map[key] ?? ''}'.trim();
      if (value.isNotEmpty && value.toLowerCase() != 'null') {
        return value;
      }
    }
    return null;
  }

  String _secureNoteSnapshotId(Map<String, dynamic> snapshot) {
    final note = snapshot['note'];
    if (note is! Map) {
      return '';
    }
    return '${note['id'] ?? ''}'.trim();
  }

  String? _secureNoteUpdatedAt(Map<String, dynamic> snapshot) {
    final note = snapshot['note'];
    if (note is! Map) {
      return null;
    }
    final updatedAt = '${note['updated_at_iso'] ?? ''}'.trim();
    return updatedAt.isEmpty ? null : updatedAt;
  }

  Object? _rewriteObject(
    Object? value,
    Map<String, String> mapping,
    List<MapEntry<String, String>> rewriteEntries,
  ) {
    if (value is String) {
      return _rewriteString(value, mapping, rewriteEntries);
    }
    if (value is List) {
      return value
          .map((item) => _rewriteObject(item, mapping, rewriteEntries))
          .toList(growable: false);
    }
    if (value is Map) {
      return {
        for (final entry in value.entries)
          '${entry.key}': _rewriteObject(entry.value, mapping, rewriteEntries),
      };
    }
    return value;
  }

  String _rewriteString(
    String value,
    Map<String, String> mapping,
    List<MapEntry<String, String>> rewriteEntries,
  ) {
    final exact = mapping[value];
    if (exact != null) {
      return exact;
    }
    if (rewriteEntries.isEmpty) {
      return value;
    }

    StringBuffer? buffer;
    var index = 0;
    while (index < value.length) {
      MapEntry<String, String>? match;
      for (final entry in rewriteEntries) {
        if (value.startsWith(entry.key, index)) {
          match = entry;
          break;
        }
      }

      if (match == null) {
        if (buffer != null) {
          buffer.write(value[index]);
        }
        index += 1;
        continue;
      }

      buffer ??= StringBuffer(value.substring(0, index));
      buffer.write(match.value);
      index += match.key.length;
    }

    return buffer?.toString() ?? value;
  }

  List<MapEntry<String, String>> _sortedRewriteEntries(
    Map<String, String> mapping,
  ) {
    final entries = mapping.entries
        .where((entry) => entry.key.isNotEmpty && entry.key != entry.value)
        .toList(growable: false);
    entries.sort((a, b) {
      final lengthCompare = b.key.length.compareTo(a.key.length);
      if (lengthCompare != 0) {
        return lengthCompare;
      }
      return a.key.compareTo(b.key);
    });
    return entries;
  }

  void _addPathMapping(
    Map<String, String> mapping,
    String rawPath,
    String destinationPath,
  ) {
    final normalizedDestination = LocalAssetPathResolver.normalizePath(
      destinationPath,
    );
    for (final key in _pathMappingKeys(rawPath)) {
      mapping.putIfAbsent(key, () => normalizedDestination);
    }
  }

  Set<String> _pathMappingKeys(String rawPath) {
    final trimmed = rawPath.trim();
    if (trimmed.isEmpty) {
      return const <String>{};
    }

    final normalized = LocalAssetPathResolver.normalizePath(trimmed);
    final keys = <String>{trimmed, normalized};

    final portable = LocalAssetPathResolver.extractPortablePath(normalized);
    if (portable != null && portable.trim().isNotEmpty) {
      keys.add(portable.trim());
    }

    final storedPortable = LocalAssetPathResolver.toStoredPortablePath(
      normalized,
    );
    if (storedPortable.trim().isNotEmpty) {
      keys.add(storedPortable.trim());
    }

    if (!normalized.startsWith('file://')) {
      try {
        keys.add(Uri.file(normalized).toString());
      } catch (_) {
        // Some mirror-relative paths are not valid file URIs on all platforms.
      }
    }

    return {
      for (final key in keys)
        if (key.trim().isNotEmpty) key.trim(),
      for (final key in keys)
        if (key.replaceAll('\\', '/').trim().isNotEmpty)
          key.replaceAll('\\', '/').trim(),
    };
  }

  _VaultMirrorPathAudit _auditRestoredLocalPaths(
    Map<String, dynamic> snapshot,
  ) {
    final missingSamples = <String>[];
    var missingCount = 0;
    var checked = 0;

    void checkPath(String context, String rawPath) {
      final path = rawPath.trim();
      if (!_looksLikeLocalPath(path)) {
        return;
      }
      checked += 1;
      if (LocalAssetPathResolver.resolveExistingPathSync(path) != null) {
        return;
      }
      missingCount += 1;
      if (missingSamples.length < 12) {
        missingSamples.add('$context -> $path');
      }
    }

    void visit(Object? value, String context) {
      if (value is Map) {
        final map = Map<dynamic, dynamic>.from(value);
        final label = '${map['label'] ?? ''}'.trim();
        final fieldValue = '${map['value'] ?? ''}'.trim();
        if (label.isNotEmpty && fieldValue.isNotEmpty) {
          if (_isReferenceAssetsJsonLabel(label)) {
            _checkReferenceAssetJson(
              rawJson: fieldValue,
              context: context,
              checkPath: checkPath,
            );
          } else if (_isPathLikeKey(label)) {
            checkPath('$context.$label', fieldValue);
          }
        }

        for (final entry in map.entries) {
          final key = '${entry.key}'.trim();
          final nextContext = key.isEmpty ? context : '$context.$key';
          final entryValue = entry.value;
          if (entryValue is String && _isPathLikeKey(key)) {
            checkPath(nextContext, entryValue);
            continue;
          }
          if (entryValue is String && _isReferenceAssetsJsonLabel(key)) {
            _checkReferenceAssetJson(
              rawJson: entryValue,
              context: nextContext,
              checkPath: checkPath,
            );
            continue;
          }
          visit(entryValue, nextContext);
        }
        return;
      }

      if (value is List) {
        for (var i = 0; i < value.length; i++) {
          visit(value[i], '$context[$i]');
        }
      }
    }

    visit(snapshot, 'snapshot');
    if (missingCount == 0) {
      debugPrint('[VaultMirrorImport] Path audit passed for $checked paths.');
      return _VaultMirrorPathAudit(
        checkedCount: checked,
        missingCount: 0,
        samples: const [],
      );
    }
    debugPrint(
      '[VaultMirrorImport] Path audit found $missingCount missing '
      'local paths after restore. First entries:\n${missingSamples.join('\n')}',
    );
    return _VaultMirrorPathAudit(
      checkedCount: checked,
      missingCount: missingCount,
      samples: List<String>.unmodifiable(missingSamples),
    );
  }

  void _checkReferenceAssetJson({
    required String rawJson,
    required String context,
    required void Function(String context, String rawPath) checkPath,
  }) {
    try {
      final decoded = jsonDecode(rawJson);
      if (decoded is! List) {
        return;
      }
      for (var i = 0; i < decoded.length; i++) {
        final item = decoded[i];
        if (item is! Map) {
          continue;
        }
        final path = '${item['path'] ?? ''}'.trim();
        if (path.isNotEmpty) {
          checkPath('$context.assets[$i].path', path);
        }
      }
    } catch (_) {
      // Invalid legacy JSON should not block restore.
    }
  }

  bool _isPathLikeKey(String key) {
    final normalized = key.trim().toLowerCase();
    return normalized.contains('path') ||
        normalized == 'image_url' ||
        normalized == 'cover_image_url' ||
        normalized == 'icon_image_path' ||
        normalized == 'photopath' ||
        normalized == 'logopath';
  }

  bool _isReferenceAssetsJsonLabel(String key) {
    return key.trim().toLowerCase() == 'reference assets json';
  }

  bool _looksLikeLocalPath(String value) {
    final path = value.trim();
    if (path.isEmpty) {
      return false;
    }
    final uri = Uri.tryParse(path);
    final scheme = uri?.scheme.toLowerCase();
    if (scheme == 'http' ||
        scheme == 'https' ||
        scheme == 'data' ||
        scheme == 'blob') {
      return false;
    }
    return path.startsWith('/') ||
        path.startsWith('file://') ||
        path.contains('/') ||
        LocalAssetPathResolver.isPortablePath(path);
  }

  Future<void> _downloadAndReplaceMirrorFile({
    required VaultMirrorImportSource source,
    required String relativePath,
    required File destination,
    required String expectedHash,
  }) async {
    final partial = File('${destination.path}.download');
    try {
      if (await partial.exists()) {
        await partial.delete();
      }
      await _copyAndValidate(
        source: source,
        relativePath: relativePath,
        destination: partial,
        expectedHash: expectedHash,
      );
      if (await destination.exists()) {
        await destination.delete();
      }
      await partial.rename(destination.path);
    } catch (_) {
      try {
        if (await partial.exists()) {
          await partial.delete();
        }
      } catch (_) {}
      rethrow;
    }
  }

  Future<bool> _fileMatchesHash(File file, String expectedHash) async {
    final expected = expectedHash.trim();
    if (expected.isEmpty || !(await file.exists())) {
      return false;
    }
    try {
      final actual = await _hashFile(file);
      return actual == expected;
    } catch (_) {
      return false;
    }
  }

  Future<void> _copyAndValidate({
    required VaultMirrorImportSource source,
    required String relativePath,
    required File destination,
    required String expectedHash,
  }) async {
    final sink = destination.openWrite();
    final hashSink = Sha256().toSync().newHashSink();
    try {
      await for (final chunk in source.openRead(relativePath)) {
        hashSink.add(chunk);
        sink.add(chunk);
      }
    } finally {
      await sink.close();
      hashSink.close();
    }
    final hash = await hashSink.hash();
    final actual = base64UrlEncode(hash.bytes);
    if (actual != expectedHash) {
      try {
        await destination.delete();
      } catch (_) {}
      throw StateError('Mirror file hash mismatch for $relativePath.');
    }
  }

  Future<void> _validateInlineFile({
    required String relativePath,
    required List<int> content,
    required VaultMirrorManifest manifest,
  }) async {
    final expected = manifest.fileHashesByPath[relativePath];
    if (expected == null || expected.isEmpty) {
      throw StateError('Mirror manifest is missing $relativePath.');
    }
    final actual = await _hashBytes(content);
    if (actual != expected) {
      throw StateError('Mirror snapshot hash mismatch.');
    }
  }

  String _safeDestination(Directory root, String relativePath) {
    final rootUri = root.absolute.uri;
    final encoded = relativePath
        .trim()
        .replaceAll('\\', '/')
        .split('/')
        .where((part) => part.isNotEmpty && part != '.' && part != '..')
        .map(Uri.encodeComponent)
        .join('/');
    final outputUri = rootUri.resolve(encoded).normalizePath();
    final output = outputUri.toFilePath();
    final rootPath = rootUri.normalizePath().toFilePath();
    if (!output.startsWith(rootPath)) {
      throw StateError('Unsafe mirror path: $relativePath');
    }
    return output;
  }

  List<dynamic> _asList(dynamic value) {
    return value is List ? value : const <dynamic>[];
  }

  double _mapProgress(int index, int total, double start, double end) {
    if (total <= 0) {
      return end;
    }
    return start + ((end - start) * (index / total).clamp(0, 1));
  }

  String _countLabel(int count, String singular) {
    return '$count $singular${count == 1 ? '' : 's'}';
  }

  Future<String> _hashBytes(List<int> bytes) async {
    final hash = await Sha256().hash(bytes);
    return base64UrlEncode(hash.bytes);
  }

  Future<String> _hashFile(File file) async {
    final hashSink = Sha256().toSync().newHashSink();
    try {
      await for (final chunk in file.openRead()) {
        hashSink.add(chunk);
      }
    } finally {
      hashSink.close();
    }
    final hash = await hashSink.hash();
    return base64UrlEncode(hash.bytes);
  }

  void _emitProgress(
    VaultSyncProgressCallback? onProgress, {
    required String message,
    required String detail,
    required double progress,
    int? processedCount,
    int? totalCount,
    int? entityCount,
    int? fileCount,
  }) {
    final bounded = progress.clamp(0, 1).toDouble();
    developer.log(
      '[VaultMirrorImport] $message - $detail (${(bounded * 100).toStringAsFixed(0)}%)',
      name: 'VaultMirrorImport',
    );
    onProgress?.call(
      VaultSyncProgressEntity(
        message: message,
        detail: detail,
        progress: bounded,
        processedCount: processedCount,
        totalCount: totalCount,
        entityCount: entityCount,
        fileCount: fileCount,
      ),
    );
  }
}

class _VaultMirrorPathAudit {
  const _VaultMirrorPathAudit({
    required this.checkedCount,
    required this.missingCount,
    required this.samples,
  });

  final int checkedCount;
  final int missingCount;
  final List<String> samples;

  bool get hasMissingPaths => missingCount > 0;
}

class _MirrorFileRestoreResult {
  const _MirrorFileRestoreResult({
    required this.pathMapping,
    required this.failedFiles,
    required this.restoredCount,
    required this.restoredBytes,
  });

  final Map<String, String> pathMapping;
  final List<String> failedFiles;
  final int restoredCount;
  final int restoredBytes;
}

/// Pure merge tie-break: should the incoming (remote) record replace the
/// existing (local) one, based on their `updatedAt` timestamps?
///
/// Rules:
///  * a **strictly newer** remote wins;
///  * on an **equal** timestamp the LOCAL record is kept;
///  * if only the remote is timestamped, remote wins; if only the local is,
///    local is kept;
///  * if neither is timestamped, the LOCAL record is kept.
///
/// The bias toward local on every tie is deliberate: a merge must never
/// silently overwrite a local edit it cannot prove is stale, and the result
/// must not depend on record ordering.
@visibleForTesting
bool mergePrefersIncomingByTimestamp(String? incomingRaw, String? existingRaw) {
  final incoming = _tryParseIso(incomingRaw);
  final existing = _tryParseIso(existingRaw);
  if (incoming != null && existing != null) {
    return incoming.isAfter(existing);
  }
  if (incoming != null) {
    return true;
  }
  if (existing != null) {
    return false;
  }
  return false;
}

DateTime? _tryParseIso(String? raw) {
  final value = raw?.trim();
  if (value == null || value.isEmpty) {
    return null;
  }
  return DateTime.tryParse(value);
}

/// Whether a tombstone should delete a record given the record's local
/// `updatedAt`. The delete wins UNLESS the local record was edited strictly
/// after the deletion — an edit newer than the delete keeps the record.
@visibleForTesting
bool mergeTombstoneWins(String? deletedAtRaw, String? localUpdatedAtRaw) {
  final deletedAt = _tryParseIso(deletedAtRaw);
  final localUpdatedAt = _tryParseIso(localUpdatedAtRaw);
  if (localUpdatedAt != null &&
      deletedAt != null &&
      localUpdatedAt.isAfter(deletedAt)) {
    return false;
  }
  return true;
}

/// Parses `snapshot['tombstones']` into `entityType -> {entityId -> deletedAt}`.
///
/// Accepts the shape emitted by the sync layer: a list of
/// `{entity_type, entity_id, deleted_at_iso}` maps. Unknown/malformed entries
/// are skipped. Returns an empty map when the field is absent.
@visibleForTesting
Map<String, Map<String, String>> parseSnapshotTombstones(Object? raw) {
  final result = <String, Map<String, String>>{};
  if (raw is! List) {
    return result;
  }
  for (final item in raw) {
    if (item is! Map) {
      continue;
    }
    final type = (item['entity_type'] ?? '').toString().trim();
    final id = (item['entity_id'] ?? '').toString().trim();
    if (type.isEmpty || id.isEmpty) {
      continue;
    }
    final deletedAt = (item['deleted_at_iso'] ?? '').toString();
    (result[type] ??= <String, String>{})[id] = deletedAt;
  }
  return result;
}
