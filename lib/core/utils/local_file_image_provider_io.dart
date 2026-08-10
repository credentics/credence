import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:pass_doc_manager/core/extensions/local_file_type_extensions.dart';
import 'package:pass_doc_manager/core/utils/local_asset_path_resolver.dart';

ImageProvider<Object>? resolveLocalFileImageProviderImpl(String? localPath) {
  final trimmed = localPath?.trim();
  if (trimmed == null || trimmed.isEmpty) {
    return null;
  }

  final normalizedPath = LocalAssetPathResolver.resolveRuntimePathSync(trimmed);
  final file = File(normalizedPath);
  if (!file.existsSync()) {
    return null;
  }
  final mime = normalizedPath.inferMimeType();
  if (!mime.isImageMimeType) {
    return null;
  }

  return FileImage(file);
}
