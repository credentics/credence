import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pass_doc_manager/app/platform/desktop_platform.dart';
import 'package:pass_doc_manager/app/theme/app_palette.dart';

/// Mixin for managing multi-select state in a list.
/// Add to any StatefulWidget that displays a list of selectable items.
mixin DesktopMultiSelectMixin<T extends StatefulWidget> on State<T> {
  final Set<String> _selectedIds = {};
  bool _isMultiSelectMode = false;

  Set<String> get selectedIds => Set.unmodifiable(_selectedIds);
  bool get isMultiSelectMode => _isMultiSelectMode;
  int get selectedCount => _selectedIds.length;

  /// Call this when an item is tapped.
  /// On desktop with Cmd/Ctrl held, it toggles multi-select.
  /// Returns true if multi-select handled the tap (don't navigate).
  bool handleItemTap(String itemId) {
    if (!DesktopPlatform.isDesktop) return false;

    // Check if Cmd (macOS) or Ctrl (Windows/Linux) is held
    final isModifierHeld = HardwareKeyboard.instance.isMetaPressed ||
        HardwareKeyboard.instance.isControlPressed;

    if (isModifierHeld) {
      setState(() {
        if (_selectedIds.contains(itemId)) {
          _selectedIds.remove(itemId);
        } else {
          _selectedIds.add(itemId);
        }
        _isMultiSelectMode = _selectedIds.isNotEmpty;
      });
      return true;
    }

    // If already in multi-select mode, a regular tap toggles too
    if (_isMultiSelectMode) {
      setState(() {
        if (_selectedIds.contains(itemId)) {
          _selectedIds.remove(itemId);
        } else {
          _selectedIds.add(itemId);
        }
        _isMultiSelectMode = _selectedIds.isNotEmpty;
      });
      return true;
    }

    return false;
  }

  void clearSelection() {
    setState(() {
      _selectedIds.clear();
      _isMultiSelectMode = false;
    });
  }

  void selectAll(List<String> allIds) {
    setState(() {
      _selectedIds.addAll(allIds);
      _isMultiSelectMode = _selectedIds.isNotEmpty;
    });
  }
}

/// Visual indicator for multi-select state on a list item.
class DesktopSelectIndicator extends StatelessWidget {
  const DesktopSelectIndicator({
    super.key,
    required this.isSelected,
    required this.isMultiSelectMode,
  });

  final bool isSelected;
  final bool isMultiSelectMode;

  @override
  Widget build(BuildContext context) {
    if (!DesktopPlatform.isDesktop || !isMultiSelectMode) {
      return const SizedBox.shrink();
    }

    final palette = context.appPalette;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: 24,
      height: 24,
      margin: const EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
        color: isSelected ? palette.primary : Colors.transparent,
        border: Border.all(
          color: isSelected ? palette.primary : palette.stroke,
          width: 2,
        ),
        borderRadius: BorderRadius.circular(6),
      ),
      child: isSelected
          ? const Icon(Icons.check_rounded, size: 16, color: Colors.white)
          : null,
    );
  }
}

/// A floating action bar shown when items are selected.
class DesktopMultiSelectActionBar extends StatelessWidget {
  const DesktopMultiSelectActionBar({
    super.key,
    required this.selectedCount,
    required this.onClearSelection,
    required this.actions,
  });

  final int selectedCount;
  final VoidCallback onClearSelection;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    if (selectedCount == 0) return const SizedBox.shrink();

    final palette = context.appPalette;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: palette.primary,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: palette.primary.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$selectedCount selected',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 12),
          ...actions,
          const SizedBox(width: 8),
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: onClearSelection,
              child: const Icon(
                Icons.close_rounded,
                size: 18,
                color: Colors.white70,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
