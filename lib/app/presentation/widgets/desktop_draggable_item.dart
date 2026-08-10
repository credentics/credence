import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pass_doc_manager/app/platform/desktop_platform.dart';
import 'package:pass_doc_manager/app/theme/app_palette.dart';

/// Data payload that can be dragged out of the app to the system.
class DraggablePayload {
  const DraggablePayload({
    required this.plainText,
    this.label = '',
  });

  /// The text content placed on the system clipboard/pasteboard when dragged.
  final String plainText;

  /// Display label shown on the drag ghost.
  final String label;
}

/// Wraps a widget to make it draggable OUT of the app on desktop.
/// Uses Flutter's native Draggable with system clipboard integration.
/// On mobile, this is a no-op wrapper.
class DesktopDraggableItem extends StatelessWidget {
  const DesktopDraggableItem({
    super.key,
    required this.child,
    required this.payload,
    this.onDragStarted,
    this.onDragEnd,
  });

  final Widget child;
  final DraggablePayload payload;
  final VoidCallback? onDragStarted;
  final VoidCallback? onDragEnd;

  @override
  Widget build(BuildContext context) {
    if (!DesktopPlatform.isDesktop) return child;

    final palette = context.appPalette;

    return LongPressDraggable<DraggablePayload>(
      data: payload,
      delay: const Duration(milliseconds: 150),
      onDragStarted: () {
        // Copy to system clipboard so external apps can paste
        Clipboard.setData(ClipboardData(text: payload.plainText));
        onDragStarted?.call();
      },
      onDragEnd: (_) => onDragEnd?.call(),
      feedback: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(12),
        shadowColor: palette.shadow.withValues(alpha: 0.24),
        color: palette.surface,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 260),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: palette.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: palette.primary.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.drag_indicator_rounded, size: 16, color: palette.primary),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  payload.label.isNotEmpty ? payload.label : 'Dragging item...',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: palette.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.4,
        child: child,
      ),
      child: child,
    );
  }
}
