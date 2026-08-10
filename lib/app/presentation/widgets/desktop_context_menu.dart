import 'package:flutter/material.dart';
import 'package:pass_doc_manager/app/platform/desktop_platform.dart';
import 'package:pass_doc_manager/app/theme/app_palette.dart';

/// A context menu action with icon, label, and callback.
class ContextMenuAction {
  const ContextMenuAction({
    required this.icon,
    required this.label,
    required this.onSelected,
    this.isDestructive = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onSelected;
  final bool isDestructive;
}

/// Wraps a child widget to show a right-click context menu on desktop.
/// On mobile, this is a no-op wrapper.
class DesktopContextMenu extends StatelessWidget {
  const DesktopContextMenu({
    super.key,
    required this.child,
    required this.actions,
  });

  final Widget child;
  final List<ContextMenuAction> actions;

  @override
  Widget build(BuildContext context) {
    if (!DesktopPlatform.isDesktop || actions.isEmpty) {
      return child;
    }

    return GestureDetector(
      onSecondaryTapUp: (details) =>
          _showContextMenu(context, details.globalPosition),
      child: child,
    );
  }

  void _showContextMenu(BuildContext context, Offset position) {
    final palette = context.appPalette;
    final RenderBox overlay =
        Overlay.of(context).context.findRenderObject()! as RenderBox;

    showMenu<void>(
      context: context,
      position: RelativeRect.fromRect(
        position & const Size(1, 1),
        Offset.zero & overlay.size,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      color: palette.surface,
      elevation: 8,
      items: actions.map((action) {
        final color =
            action.isDestructive ? palette.danger : palette.textPrimary;
        return PopupMenuItem<void>(
          onTap: action.onSelected,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(action.icon, size: 18, color: color),
              const SizedBox(width: 10),
              Text(
                action.label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: color,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
