import 'package:flutter/material.dart';
import 'package:pass_doc_manager/app/platform/desktop_platform.dart';
import 'package:pass_doc_manager/app/theme/app_palette.dart';

/// A card wrapper that adds hover states on desktop platforms.
/// Provides a subtle background highlight and pointer cursor on hover.
/// On mobile, renders the child without modification.
class DesktopHoverCard extends StatefulWidget {
  const DesktopHoverCard({
    super.key,
    required this.child,
    this.onTap,
    this.onDoubleTap,
    this.onSecondaryTap,
    this.borderRadius = 16,
    this.hoverElevation = 2,
    this.tooltip,
    this.cursor = SystemMouseCursors.click,
  });

  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onDoubleTap;
  final VoidCallback? onSecondaryTap;
  final double borderRadius;
  final double hoverElevation;
  final String? tooltip;
  final MouseCursor cursor;

  @override
  State<DesktopHoverCard> createState() => _DesktopHoverCardState();
}

class _DesktopHoverCardState extends State<DesktopHoverCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    final isDesktop = DesktopPlatform.isDesktop;

    Widget card = AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeOutCubic,
      decoration: isDesktop && _isHovered
          ? BoxDecoration(
              color: palette.surfaceSoft,
              borderRadius: BorderRadius.circular(widget.borderRadius),
              boxShadow: [
                BoxShadow(
                  color: palette.shadow.withValues(alpha: 0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            )
          : BoxDecoration(
              borderRadius: BorderRadius.circular(widget.borderRadius),
            ),
      child: widget.child,
    );

    if (isDesktop) {
      card = MouseRegion(
        cursor: widget.cursor,
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          onDoubleTap: widget.onDoubleTap,
          onSecondaryTap: widget.onSecondaryTap,
          child: card,
        ),
      );

      if (widget.tooltip != null) {
        card = Tooltip(
          message: widget.tooltip!,
          waitDuration: const Duration(milliseconds: 600),
          child: card,
        );
      }
    } else {
      card = GestureDetector(
        onTap: widget.onTap,
        child: card,
      );
    }

    return card;
  }
}
