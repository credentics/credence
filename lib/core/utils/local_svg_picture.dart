import 'package:flutter/widgets.dart';
import 'package:pass_doc_manager/core/utils/local_svg_picture_stub.dart'
    if (dart.library.io) 'package:pass_doc_manager/core/utils/local_svg_picture_io.dart';

Widget? resolveLocalSvgPicture(
  String? localPath, {
  required double width,
  required double height,
  BoxFit fit = BoxFit.cover,
}) {
  return resolveLocalSvgPictureImpl(
    localPath,
    width: width,
    height: height,
    fit: fit,
  );
}
