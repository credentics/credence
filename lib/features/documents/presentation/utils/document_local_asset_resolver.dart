import 'dart:convert';

import 'package:pass_doc_manager/core/utils/local_asset_path_resolver.dart';
import 'package:pass_doc_manager/domain/documents/entities/document_detail_entity.dart';
import 'package:pass_doc_manager/domain/documents/entities/document_metadata_field_labels.dart';

class DocumentLocalAssetResolver {
  const DocumentLocalAssetResolver._();

  /// Initializes the cached app support path. Call once at startup or lazily.
  static Future<void> _ensureAppSupportPath() async {
    await LocalAssetPathResolver.initialize();
  }

  static String normalizeLocalPath(String rawPath) {
    return LocalAssetPathResolver.normalizePath(rawPath);
  }

  /// Resolves a path that may be absolute or relative to app support.
  /// Checks: absolute path → relative under appSupport → relative under
  /// appSupport/document_images (for archive `files/` prefix).
  static String? _resolveExistingFile(String rawPath) {
    return LocalAssetPathResolver.resolveExistingPathSync(rawPath);
  }

  static Future<String?> resolveFirstExistingSharePath(
    DocumentDetailEntity detail,
  ) async {
    await _ensureAppSupportPath();
    return resolveFirstExistingSharePathSync(detail);
  }

  static String? resolveFirstExistingSharePathSync(
    DocumentDetailEntity detail,
  ) {
    final directCandidates = <String>[
      _fieldValueByLabel(
            detail: detail,
            label: DocumentMetadataFieldLabels.previewImagePath,
          ) ??
          '',
      _fieldValueByLabel(
            detail: detail,
            label: DocumentMetadataFieldLabels.frontImagePath,
          ) ??
          '',
      _fieldValueByLabel(
            detail: detail,
            label: DocumentMetadataFieldLabels.backImagePath,
          ) ??
          '',
      _fieldValueByLabel(
            detail: detail,
            label: DocumentMetadataFieldLabels.referenceAssetPath,
          ) ??
          '',
    ];

    for (final candidate in directCandidates) {
      if (candidate.isEmpty) continue;
      final resolved = _resolveExistingFile(candidate);
      if (resolved != null) return resolved;
    }

    final referenceAssetsRaw = _fieldValueByLabel(
      detail: detail,
      label: DocumentMetadataFieldLabels.referenceAssetsJson,
    );
    if ((referenceAssetsRaw ?? '').trim().isEmpty) {
      return null;
    }

    try {
      final decoded = jsonDecode(referenceAssetsRaw!);
      if (decoded is List) {
        for (final item in decoded) {
          if (item is! Map) continue;
          final path = (item['path'] ?? '').toString().trim();
          if (path.isEmpty) continue;
          final resolved = _resolveExistingFile(path);
          if (resolved != null) return resolved;
        }
      }
    } catch (_) {
      return null;
    }

    return null;
  }

  static String? _fieldValueByLabel({
    required DocumentDetailEntity detail,
    required String label,
  }) {
    final normalized = _normalizeLabel(label);
    for (final field in detail.structuredFields) {
      if (_normalizeLabel(field.label) == normalized) {
        final value = field.value.trim();
        if (value.isNotEmpty) {
          return value;
        }
      }
    }
    return null;
  }

  static String _normalizeLabel(String value) => value.trim().toLowerCase();
}
