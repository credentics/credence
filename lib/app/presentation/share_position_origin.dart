import 'package:flutter/material.dart';

Rect resolveSharePositionOrigin(BuildContext context) {
  final renderObject = context.findRenderObject();
  if (renderObject is RenderBox &&
      renderObject.attached &&
      renderObject.hasSize &&
      renderObject.size.width > 0 &&
      renderObject.size.height > 0) {
    final origin = renderObject.localToGlobal(Offset.zero) & renderObject.size;
    if (origin.width > 0 &&
        origin.height > 0 &&
        origin.left.isFinite &&
        origin.top.isFinite) {
      return origin;
    }
  }

  final size = MediaQuery.maybeSizeOf(context) ?? const Size(1, 1);
  final safeWidth = size.width > 1 ? size.width : 1.0;
  final safeHeight = size.height > 1 ? size.height : 1.0;

  return Rect.fromCenter(
    center: Offset(safeWidth / 2, safeHeight / 2),
    width: 1,
    height: 1,
  );
}
