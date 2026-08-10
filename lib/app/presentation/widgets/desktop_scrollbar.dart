import 'package:flutter/material.dart';
import 'package:pass_doc_manager/app/platform/desktop_platform.dart';

/// Wraps a scrollable child with a visible, grabbable scrollbar on desktop.
/// On mobile, returns the child without modification (uses default scrolling).
class DesktopScrollbar extends StatelessWidget {
  const DesktopScrollbar({
    super.key,
    required this.controller,
    required this.child,
    this.thumbVisibility,
  });

  final ScrollController controller;
  final Widget child;
  final bool? thumbVisibility;

  @override
  Widget build(BuildContext context) {
    if (!DesktopPlatform.isDesktop) return child;

    return Scrollbar(
      controller: controller,
      thumbVisibility: thumbVisibility ?? true,
      thickness: 8,
      radius: const Radius.circular(4),
      interactive: true,
      child: child,
    );
  }
}
