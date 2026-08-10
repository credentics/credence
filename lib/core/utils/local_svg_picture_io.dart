import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:pass_doc_manager/core/utils/local_asset_path_resolver.dart';

Widget? resolveLocalSvgPictureImpl(
  String? localPath, {
  required double width,
  required double height,
  BoxFit fit = BoxFit.cover,
}) {
  final trimmed = localPath?.trim();
  if (trimmed == null || trimmed.isEmpty) {
    return null;
  }

  if (!trimmed.toLowerCase().endsWith('.svg')) {
    return null;
  }

  final resolvedPath = LocalAssetPathResolver.resolveRuntimePathSync(trimmed);
  final file = File(resolvedPath);
  if (!file.existsSync()) {
    return null;
  }

  return SvgPicture.file(file, width: width, height: height, fit: fit);
}
