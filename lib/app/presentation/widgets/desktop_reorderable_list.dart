import 'package:flutter/material.dart';
import 'package:pass_doc_manager/app/platform/desktop_platform.dart';
import 'package:pass_doc_manager/app/theme/app_palette.dart';

/// A reorderable list that uses drag-to-reorder on both mobile and desktop.
/// On desktop, it provides a drag handle and ghost preview.
/// Uses Flutter's built-in ReorderableListView with desktop polish.
class DesktopReorderableList<T> extends StatelessWidget {
  const DesktopReorderableList({
    super.key,
    required this.items,
    required this.itemBuilder,
    required this.onReorder,
    this.padding = EdgeInsets.zero,
    this.physics,
    this.shrinkWrap = false,
  });

  final List<T> items;
  final Widget Function(BuildContext context, T item, int index, bool isDesktop) itemBuilder;
  final void Function(int oldIndex, int newIndex) onReorder;
  final EdgeInsetsGeometry padding;
  final ScrollPhysics? physics;
  final bool shrinkWrap;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    final isDesktop = DesktopPlatform.isDesktop;

    return ReorderableListView.builder(
      shrinkWrap: shrinkWrap,
      physics: physics,
      padding: padding.resolve(Directionality.of(context)),
      buildDefaultDragHandles: false,
      proxyDecorator: (child, index, animation) {
        return AnimatedBuilder(
          animation: animation,
          builder: (context, child) {
            final elevation = Tween<double>(begin: 0, end: 8)
                .animate(CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOutCubic,
                ))
                .value;
            return Material(
              elevation: elevation,
              color: palette.surface,
              borderRadius: BorderRadius.circular(14),
              shadowColor: palette.shadow.withValues(alpha: 0.18),
              child: child,
            );
          },
          child: child,
        );
      },
      onReorder: (oldIndex, newIndex) {
        if (newIndex > oldIndex) newIndex -= 1;
        onReorder(oldIndex, newIndex);
      },
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return KeyedSubtree(
          key: ValueKey('reorderable_$index'),
          child: Row(
            children: [
              if (isDesktop)
                ReorderableDragStartListener(
                  index: index,
                  child: MouseRegion(
                    cursor: SystemMouseCursors.grab,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 8,
                      ),
                      child: Icon(
                        Icons.drag_indicator_rounded,
                        size: 20,
                        color: palette.textMuted,
                      ),
                    ),
                  ),
                )
              else
                ReorderableDragStartListener(
                  index: index,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 8,
                    ),
                    child: Icon(
                      Icons.drag_handle_rounded,
                      size: 20,
                      color: palette.textMuted,
                    ),
                  ),
                ),
              Expanded(
                child: itemBuilder(context, item, index, isDesktop),
              ),
            ],
          ),
        );
      },
    );
  }
}
