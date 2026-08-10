import 'dart:io';

import 'package:flutter/material.dart';
import 'package:pass_doc_manager/core/extensions/local_file_type_extensions.dart';
import 'package:pass_doc_manager/core/utils/local_asset_path_resolver.dart';
import 'package:pass_doc_manager/domain/collections/entities/collection_block_entity.dart';
import 'package:pass_doc_manager/features/documents/presentation/pages/document_file_preview_page.dart';
import 'package:pass_doc_manager/l10n/l10n.dart';

Future<void> openCollectionFilePreview(
  BuildContext context,
  CollectionBlockEntity block,
) async {
  final rawPath = (block.filePath ?? block.imageUrl ?? '').trim();
  final resolvedPath = LocalAssetPathResolver.resolveRuntimePathSync(rawPath);
  if (resolvedPath.isEmpty) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.l10n.collectionDetailNoFileAttached)),
    );
    return;
  }

  var previewPath = resolvedPath;
  if (!File(previewPath).existsSync()) {
    final fallbackPath = await _findRestoredMirrorFileForBlock(
      block: block,
      rawPath: rawPath,
      resolvedPath: resolvedPath,
    );
    if (fallbackPath == null) {
      final appSupport = await LocalAssetPathResolver.getAppSupportPath();
      debugPrint(
        '[CollectionFileOpen] Missing file for block=${block.id} '
        'title="${block.title}" raw="$rawPath" resolved="$resolvedPath" '
        'appSupport="$appSupport"',
      );
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.collectionDetailFileNotFound)),
      );
      return;
    }
    debugPrint(
      '[CollectionFileOpen] Recovered missing file for block=${block.id} '
      'title="${block.title}" resolved="$resolvedPath" fallback="$fallbackPath"',
    );
    previewPath = fallbackPath;
  }

  if (!context.mounted) return;
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => DocumentFilePreviewPage(
        filePath: previewPath,
        title: block.title,
        fileName: LocalAssetPathResolver.portableFileName(previewPath),
        mimeType: previewPath.inferMimeType(),
      ),
    ),
  );
}

Future<String?> _findRestoredMirrorFileForBlock({
  required CollectionBlockEntity block,
  required String rawPath,
  required String resolvedPath,
}) async {
  final appSupport = await LocalAssetPathResolver.getAppSupportPath();
  if (appSupport == null || appSupport.trim().isEmpty) {
    return null;
  }
  final root = Directory(
    '$appSupport${Platform.pathSeparator}vault_mirror_restored',
  );
  if (!root.existsSync()) {
    return null;
  }

  final expectedExtension = _extension(rawPath).isNotEmpty
      ? _extension(rawPath)
      : _extension(resolvedPath);
  final candidates = _candidateTokens(block: block, rawPath: rawPath);
  if (candidates.isEmpty) {
    return null;
  }

  await for (final entity in root.list(recursive: true, followLinks: false)) {
    if (entity is! File) {
      continue;
    }
    final path = entity.path;
    if (expectedExtension.isNotEmpty && _extension(path) != expectedExtension) {
      continue;
    }
    final normalizedName = _searchToken(
      LocalAssetPathResolver.portableFileName(path),
    );
    if (normalizedName.isEmpty) {
      continue;
    }
    if (candidates.any(
      (candidate) =>
          normalizedName.contains(candidate) ||
          candidate.contains(normalizedName),
    )) {
      return path;
    }
  }
  return null;
}

Set<String> _candidateTokens({
  required CollectionBlockEntity block,
  required String rawPath,
}) {
  final tokens = <String>{};
  void add(String value) {
    final token = _searchToken(value);
    if (token.length >= 4) {
      tokens.add(token);
    }
  }

  add(block.title);
  add(block.subtitle);
  add(LocalAssetPathResolver.portableFileName(rawPath));
  return tokens;
}

String _extension(String path) {
  final fileName = LocalAssetPathResolver.portableFileName(path).toLowerCase();
  final dotIndex = fileName.lastIndexOf('.');
  if (dotIndex <= 0 || dotIndex == fileName.length - 1) {
    return '';
  }
  return fileName.substring(dotIndex);
}

String _searchToken(String value) {
  final fileName = value.split('.').first;
  return fileName.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '');
}
