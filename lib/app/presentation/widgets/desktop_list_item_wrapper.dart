import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pass_doc_manager/app/platform/desktop_platform.dart';
import 'package:pass_doc_manager/app/presentation/widgets/desktop_context_menu.dart';
import 'package:pass_doc_manager/app/theme/app_palette.dart';

/// Wraps any list item widget with desktop-specific enhancements:
/// - Hover state with subtle background change
/// - Right-click context menu
/// - Double-click to open/edit
/// - Proper cursor changes
/// - Cmd/Ctrl+click for multi-select (when callback provided)
///
/// On mobile, this is a transparent passthrough.
///
/// Usage:
/// ```dart
/// DesktopListItemWrapper(
///   onDoubleTap: () => openDetail(item),
///   contextActions: [
///     ContextMenuAction(icon: Icons.copy, label: 'Copy Password', onSelected: () => copy(item.password)),
///     ContextMenuAction(icon: Icons.edit, label: 'Edit', onSelected: () => edit(item)),
///     ContextMenuAction(icon: Icons.delete, label: 'Delete', onSelected: () => delete(item), isDestructive: true),
///   ],
///   child: existingCardWidget,
/// )
/// ```
class DesktopListItemWrapper extends StatefulWidget {
  const DesktopListItemWrapper({
    super.key,
    required this.child,
    this.onDoubleTap,
    this.contextActions = const [],
    this.onCmdClick,
    this.isSelected = false,
    this.borderRadius = 24,
  });

  final Widget child;
  final VoidCallback? onDoubleTap;
  final List<ContextMenuAction> contextActions;
  final VoidCallback? onCmdClick;
  final bool isSelected;
  final double borderRadius;

  @override
  State<DesktopListItemWrapper> createState() => _DesktopListItemWrapperState();
}

class _DesktopListItemWrapperState extends State<DesktopListItemWrapper> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    if (!DesktopPlatform.isDesktop) return widget.child;

    final palette = context.appPalette;

    Widget child = AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(widget.borderRadius),
        color: widget.isSelected
            ? palette.primarySoft
            : _hovered
                ? palette.surfaceSoft.withValues(alpha: 0.6)
                : Colors.transparent,
      ),
      child: widget.child,
    );

    child = MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onDoubleTap: widget.onDoubleTap,
        onSecondaryTapUp: widget.contextActions.isNotEmpty
            ? (details) => _showContextMenu(context, details.globalPosition)
            : null,
        child: child,
      ),
    );

    return child;
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
      items: widget.contextActions.map((action) {
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
