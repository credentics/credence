import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pass_doc_manager/core/utils/local_asset_path_resolver.dart';
import 'package:pass_doc_manager/domain/bundles/entities/bundle_entity.dart';
import 'package:pass_doc_manager/domain/bundles/entities/bundle_event.dart';
import 'package:pass_doc_manager/domain/bundles/entities/bundle_item_ref.dart';
import 'package:pass_doc_manager/domain/bundles/entities/bundle_item_type.dart';
import 'package:pass_doc_manager/domain/bundles/entities/bundle_status.dart';
import 'package:pass_doc_manager/domain/bundles/repositories/bundle_repository.dart';
import 'package:pass_doc_manager/domain/collections/entities/collection_block_entity.dart';
import 'package:pass_doc_manager/domain/collections/entities/collection_block_type.dart';
import 'package:pass_doc_manager/domain/collections/repositories/collections_repository.dart';
import 'package:pass_doc_manager/domain/credentials/repositories/credential_repository.dart';
import 'package:pass_doc_manager/domain/documents/entities/document_detail_entity.dart';
import 'package:pass_doc_manager/domain/documents/entities/document_metadata_field_labels.dart';
import 'package:pass_doc_manager/domain/documents/repositories/document_repository.dart';

class BundleExportRequest {
  const BundleExportRequest({
    required this.bundle,
    required this.encrypt,
    this.passphrase,
  });

  final BundleEntity bundle;
  final bool encrypt;
  final String? passphrase;
}

class BundleExportResult {
  const BundleExportResult({
    required this.filePath,
    required this.sizeBytes,
    required this.itemCount,
    required this.exportedAt,
  });

  final String filePath;
  final int sizeBytes;
  final int itemCount;
  final DateTime exportedAt;
}

/// Builds an encrypted-or-plain ZIP archive containing only real files.
///
/// File-backed document items copy their resolvable local PDF/image assets.
/// Data-only references remain visible in the bundle UI but are intentionally
/// skipped here: bundle export must never create metadata `.txt` placeholders.
/// On success the bundle is marked `exported` with an event appended.
class BundleExportService {
  BundleExportService({
    required this.bundleRepository,
    required this.collectionsRepository,
    required this.credentialRepository,
    required this.documentRepository,
  });

  final BundleRepository bundleRepository;
  final CollectionsRepository collectionsRepository;
  final CredentialRepository credentialRepository;
  final DocumentRepository documentRepository;

  Future<BundleExportResult> export(BundleExportRequest request) async {
    final bundle = request.bundle;
    if (request.encrypt) {
      final pass = request.passphrase?.trim() ?? '';
      if (pass.isEmpty) {
        throw ArgumentError('Encryption requested but passphrase is empty.');
      }
    }

    final archive = Archive();
    var includedFileCount = 0;
    final usedPaths = <String>{};

    for (final item in bundle.items) {
      final renderedItems = await _renderItem(item);
      for (final rendered in renderedItems) {
        final relativePath = _uniquePath(rendered.relativePath, usedPaths);
        archive.addFile(
          ArchiveFile(relativePath, rendered.bytes.length, rendered.bytes),
        );
        includedFileCount++;
      }
    }

    if (includedFileCount == 0) {
      throw StateError('No real files could be resolved for this bundle.');
    }

    final zipBytes = ZipEncoder(
      password: request.encrypt ? request.passphrase : null,
    ).encode(archive);

    final filePath = await _writeArchive(
      bundle: bundle,
      bytes: Uint8List.fromList(zipBytes),
    );

    // Update the bundle: record event, bump lastExportedAt, status → exported.
    final now = DateTime.now();
    final updated = bundle.copyWith(
      status: BundleStatus.exported,
      lastExportedAt: now,
      lastExportPath: filePath,
      history: [
        ...bundle.history,
        BundleEvent(
          id: '',
          kind: BundleEventKind.exported,
          at: now,
          detail: request.encrypt ? 'encrypted' : 'plain',
        ),
      ],
    );
    await bundleRepository.saveBundle(updated);

    return BundleExportResult(
      filePath: filePath,
      sizeBytes: zipBytes.length,
      itemCount: includedFileCount,
      exportedAt: now,
    );
  }

  // ---------------------------------------------------------------------------
  // Rendering

  Future<List<_RenderedItem>> _renderItem(BundleItemRef item) async {
    switch (item.type) {
      case BundleItemType.credential:
      case BundleItemType.note:
        return const <_RenderedItem>[];
      case BundleItemType.identityCard:
      case BundleItemType.document:
        return _renderDocument(item);
      case BundleItemType.collection:
        return _renderCollection(item);
    }
  }

  Future<List<_RenderedItem>> _renderDocument(BundleItemRef item) async {
    try {
      final detail = await documentRepository.getDocumentDetail(
        documentId: item.refId,
      );
      final assets = _resolveDocumentAssets(detail);
      if (assets.isEmpty) {
        return const <_RenderedItem>[];
      }

      final folderName = _safeFileName(
        detail.screenTitle,
        fallback: detail.fileName.trim().isEmpty ? item.refId : detail.fileName,
      );
      final baseFileName = _safeFileName(
        item.displayName,
        fallback: detail.screenTitle.trim().isEmpty
            ? folderName
            : detail.screenTitle,
      );
      final rendered = <_RenderedItem>[];

      for (var index = 0; index < assets.length; index++) {
        final asset = assets[index];
        try {
          final bytes = await File(asset.path).readAsBytes();
          final extension = _documentAssetExtension(asset);
          final suffix = _documentAssetSuffix(
            asset: asset,
            index: index,
            total: assets.length,
          );
          final fallbackName = 'document_${index + 1}$extension';
          final fileName = _safeArchiveFileName(
            '$baseFileName$suffix$extension',
            fallback: fallbackName,
          );
          rendered.add(
            _RenderedItem(
              relativePath: 'documents/$folderName/$fileName',
              bytes: bytes,
            ),
          );
        } catch (error) {
          debugPrint(
            '[BundleExport] Document asset read failed '
            '(${asset.path}): $error',
          );
        }
      }

      if (rendered.isEmpty) {
        return const <_RenderedItem>[];
      }

      return rendered;
    } catch (error) {
      debugPrint('[BundleExport] Document render failed: $error');
      return const <_RenderedItem>[];
    }
  }

  Future<List<_RenderedItem>> _renderCollection(BundleItemRef item) async {
    try {
      final collection = await collectionsRepository.getCollectionById(
        collectionId: item.refId,
      );
      final folderName = _safeFileName(collection.name, fallback: item.refId);
      final rendered = <_RenderedItem>[];
      final blocks =
          collection.blocks
              .where(
                (block) =>
                    block.type == CollectionBlockType.document ||
                    block.type == CollectionBlockType.image,
              )
              .toList(growable: false)
            ..sort((a, b) => a.position.compareTo(b.position));

      for (var index = 0; index < blocks.length; index++) {
        final block = blocks[index];
        final assetPath = _collectionBlockAssetPath(block);
        if (assetPath == null) {
          continue;
        }
        try {
          final bytes = await File(assetPath).readAsBytes();
          final extension = _extensionFromValue(assetPath);
          final fallbackName =
              'collection_file_${index + 1}${extension.isEmpty ? '.bin' : extension}';
          final title = block.title.trim().isNotEmpty
              ? block.title.trim()
              : _basenameWithoutExtension(assetPath);
          final fileName = _safeArchiveFileName(
            '${_safeFileName(title, fallback: 'collection_file_${index + 1}')}${extension.isEmpty ? '' : extension}',
            fallback: fallbackName,
          );
          rendered.add(
            _RenderedItem(
              relativePath: 'collections/$folderName/$fileName',
              bytes: bytes,
            ),
          );
        } catch (error) {
          debugPrint(
            '[BundleExport] Collection asset read failed '
            '(${block.id}): $error',
          );
        }
      }

      return rendered;
    } catch (error) {
      debugPrint('[BundleExport] Collection render failed: $error');
      return const <_RenderedItem>[];
    }
  }

  List<_ResolvedDocumentAsset> _resolveDocumentAssets(
    DocumentDetailEntity detail,
  ) {
    final assets = <_ResolvedDocumentAsset>[];
    final seenPaths = <String>{};

    void addCandidate({
      required String rawPath,
      String? preferredName,
      String? preferredLabel,
    }) {
      final trimmed = rawPath.trim();
      if (trimmed.isEmpty) {
        return;
      }
      final resolved = LocalAssetPathResolver.resolveExistingPathSync(trimmed);
      if (resolved == null || !seenPaths.add(resolved)) {
        return;
      }
      assets.add(
        _ResolvedDocumentAsset(
          path: resolved,
          name: (preferredName ?? '').trim(),
          label: (preferredLabel ?? '').trim(),
        ),
      );
    }

    final referenceName = _fieldValueByLabel(
      detail: detail,
      label: DocumentMetadataFieldLabels.referenceAssetName,
    );
    final referenceLabel = _fieldValueByLabel(
      detail: detail,
      label: DocumentMetadataFieldLabels.referenceAssetLabel,
    );

    addCandidate(
      rawPath:
          _fieldValueByLabel(
            detail: detail,
            label: DocumentMetadataFieldLabels.referenceAssetPath,
          ) ??
          '',
      preferredName: referenceName,
      preferredLabel: referenceLabel,
    );
    addCandidate(
      rawPath:
          _fieldValueByLabel(
            detail: detail,
            label: DocumentMetadataFieldLabels.frontImagePath,
          ) ??
          '',
      preferredName: detail.fileName,
      preferredLabel: 'front',
    );
    addCandidate(
      rawPath:
          _fieldValueByLabel(
            detail: detail,
            label: DocumentMetadataFieldLabels.backImagePath,
          ) ??
          '',
      preferredLabel: 'back',
    );
    addCandidate(
      rawPath:
          _fieldValueByLabel(
            detail: detail,
            label: DocumentMetadataFieldLabels.previewImagePath,
          ) ??
          '',
      preferredLabel: 'preview',
    );

    final referenceAssetsRaw = _fieldValueByLabel(
      detail: detail,
      label: DocumentMetadataFieldLabels.referenceAssetsJson,
    );
    if ((referenceAssetsRaw ?? '').trim().isEmpty) {
      return assets;
    }

    try {
      final decoded = jsonDecode(referenceAssetsRaw!);
      if (decoded is! List) {
        return assets;
      }
      for (final item in decoded) {
        if (item is! Map) {
          continue;
        }
        final map = Map<String, dynamic>.from(item);
        addCandidate(
          rawPath: (map['path'] ?? '').toString(),
          preferredName: (map['name'] ?? '').toString(),
          preferredLabel: (map['label'] ?? '').toString(),
        );
      }
    } catch (error) {
      debugPrint('[BundleExport] Reference assets decode failed: $error');
    }

    return assets;
  }

  String? _fieldValueByLabel({
    required DocumentDetailEntity detail,
    required String label,
  }) {
    final normalized = _normalizeLabel(label);
    for (final field in detail.structuredFields) {
      if (_normalizeLabel(field.label) != normalized) {
        continue;
      }
      final value = field.value.trim();
      if (value.isNotEmpty) {
        return value;
      }
    }
    return null;
  }

  String _normalizeLabel(String value) => value.trim().toLowerCase();

  // ---------------------------------------------------------------------------
  // File writing

  Future<String> _writeArchive({
    required BundleEntity bundle,
    required Uint8List bytes,
  }) async {
    final dir = await getApplicationDocumentsDirectory();
    final exportsDir = Directory('${dir.path}/bundles');
    if (!await exportsDir.exists()) {
      await exportsDir.create(recursive: true);
    }
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final safeTitle = _safeFileName(bundle.title, fallback: bundle.id);
    final file = File('${exportsDir.path}/${safeTitle}_$timestamp.zip');
    await file.writeAsBytes(bytes, flush: true);
    return file.path;
  }

  // ---------------------------------------------------------------------------
  // Helpers

  String _safeFileName(String value, {required String fallback}) {
    final sanitized = value
        .replaceAll(RegExp(r'[^A-Za-z0-9_\-\s]'), '')
        .trim()
        .replaceAll(RegExp(r'\s+'), '_');
    return sanitized.isEmpty ? fallback : sanitized;
  }

  String _safeArchiveFileName(String value, {required String fallback}) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return fallback;
    }
    final dotIndex = trimmed.lastIndexOf('.');
    final stem = dotIndex > 0 ? trimmed.substring(0, dotIndex) : trimmed;
    final extension = dotIndex > 0 ? trimmed.substring(dotIndex) : '';
    final safeStem = _safeFileName(stem, fallback: fallback);
    final safeExtension = extension.replaceAll(RegExp(r'[^A-Za-z0-9.]'), '');
    return safeExtension.isEmpty ? safeStem : '$safeStem$safeExtension';
  }

  String _extensionFromValue(String value) {
    final fileName = value.trim().split(RegExp(r'[\\/]')).last;
    final dotIndex = fileName.lastIndexOf('.');
    if (dotIndex <= 0) {
      return '';
    }
    return fileName.substring(dotIndex);
  }

  String _basenameWithoutExtension(String value) {
    final fileName = value.trim().split(RegExp(r'[\\/]')).last;
    final dotIndex = fileName.lastIndexOf('.');
    if (dotIndex <= 0) {
      return fileName;
    }
    return fileName.substring(0, dotIndex);
  }

  String? _collectionBlockAssetPath(CollectionBlockEntity block) {
    final rawPath = switch (block.type) {
      CollectionBlockType.document => block.filePath,
      CollectionBlockType.image => block.imageUrl,
      _ => null,
    };
    final trimmed = (rawPath ?? '').trim();
    if (trimmed.isEmpty) {
      return null;
    }
    return LocalAssetPathResolver.resolveExistingPathSync(trimmed);
  }

  String _documentAssetExtension(_ResolvedDocumentAsset asset) {
    final nameExtension = _extensionFromValue(asset.name);
    if (nameExtension.isNotEmpty) {
      return nameExtension;
    }
    return _extensionFromValue(asset.path);
  }

  String _documentAssetSuffix({
    required _ResolvedDocumentAsset asset,
    required int index,
    required int total,
  }) {
    if (total <= 1) {
      return '';
    }
    final safeLabel = _safeLabelSegment(asset.label);
    if (safeLabel.isNotEmpty) {
      return '_$safeLabel';
    }
    return '_${index + 1}';
  }

  String _safeLabelSegment(String value) {
    return value
        .replaceAll(RegExp(r'[^A-Za-z0-9_\-\s]'), '')
        .trim()
        .replaceAll(RegExp(r'\s+'), '_')
        .toLowerCase();
  }

  String _uniquePath(String candidate, Set<String> used) {
    if (!used.contains(candidate)) {
      used.add(candidate);
      return candidate;
    }
    final dotIdx = candidate.lastIndexOf('.');
    final base = dotIdx > 0 ? candidate.substring(0, dotIdx) : candidate;
    final ext = dotIdx > 0 ? candidate.substring(dotIdx) : '';
    var idx = 2;
    while (used.contains('${base}_$idx$ext')) {
      idx++;
    }
    final resolved = '${base}_$idx$ext';
    used.add(resolved);
    return resolved;
  }
}

class _RenderedItem {
  const _RenderedItem({required this.relativePath, required this.bytes});

  final String relativePath;
  final Uint8List bytes;
}

class _ResolvedDocumentAsset {
  const _ResolvedDocumentAsset({
    required this.path,
    required this.name,
    required this.label,
  });

  final String path;
  final String name;
  final String label;
}
