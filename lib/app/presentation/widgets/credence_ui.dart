import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:pass_doc_manager/app/theme/app_palette.dart';

const String _credenceFontDisplay = 'Manrope';
const String _credenceFontBody = 'Manrope';
const String _credenceFontMono = 'JetBrains Mono';

class CredenceTokens {
  const CredenceTokens._();

  static const double cardRadius = 22;
  static const double controlRadius = 16;
  static const double iconButtonSize = 38;
  static const EdgeInsets screenPadding = EdgeInsets.symmetric(horizontal: 22);
}

class CredenceHeader extends StatelessWidget {
  const CredenceHeader({
    super.key,
    required this.title,
    this.eyebrow,
    this.leading,
    this.actions = const [],
    this.padding = const EdgeInsets.fromLTRB(22, 6, 22, 10),
  });

  final String title;
  final String? eyebrow;
  final Widget? leading;
  final List<Widget> actions;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    return Padding(
      padding: padding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (leading != null) ...[leading!, const SizedBox(width: 12)],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (eyebrow != null && eyebrow!.trim().isNotEmpty) ...[
                  Text(
                    eyebrow!,
                    style: TextStyle(
                      fontFamily: _credenceFontMono,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.1,
                      color: palette.textMuted,
                    ),
                  ),
                  const SizedBox(height: 5),
                ],
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: _credenceFontDisplay,
                    fontSize: 26,
                    height: 1.05,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.65,
                    color: palette.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          if (actions.isNotEmpty) ...[
            const SizedBox(width: 12),
            Row(mainAxisSize: MainAxisSize.min, children: actions),
          ],
        ],
      ),
    );
  }
}

class CredenceIconButton extends StatelessWidget {
  const CredenceIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.tooltip,
    this.backgroundColor,
    this.foregroundColor,
    this.size = CredenceTokens.iconButtonSize,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final String? tooltip;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double size;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    final button = Material(
      color: backgroundColor ?? palette.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(size / 2),
        side: BorderSide(color: palette.stroke),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(size / 2),
        child: SizedBox(
          width: size,
          height: size,
          child: Icon(
            icon,
            size: size < 42 ? 18 : 21,
            color: foregroundColor ?? palette.textPrimary,
          ),
        ),
      ),
    );
    if (tooltip == null || tooltip!.trim().isEmpty) return button;
    return Tooltip(message: tooltip, child: button);
  }
}

class CredenceCard extends StatelessWidget {
  const CredenceCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(18),
    this.margin,
    this.backgroundColor,
    this.borderColor,
    this.radius = CredenceTokens.cardRadius,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final Color? backgroundColor;
  final Color? borderColor;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    final content = Material(
      color: backgroundColor ?? palette.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radius),
        side: BorderSide(color: borderColor ?? palette.stroke),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(radius),
        child: Padding(padding: padding, child: child),
      ),
    );
    if (margin == null) return content;
    return Padding(padding: margin!, child: content);
  }
}

class CredenceSectionLabel extends StatelessWidget {
  const CredenceSectionLabel({
    super.key,
    required this.label,
    this.trailing,
    this.padding = const EdgeInsets.symmetric(horizontal: 22),
  });

  final String label;
  final Widget? trailing;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    return Padding(
      padding: padding,
      child: Row(
        children: [
          Expanded(
            child: Text(
              label.toUpperCase(),
              style: TextStyle(
                fontFamily: _credenceFontMono,
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.25,
                color: palette.textMuted,
              ),
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

class CredenceSearchField extends StatelessWidget {
  const CredenceSearchField({
    super.key,
    required this.hintText,
    this.controller,
    this.focusNode,
    this.onChanged,
    this.onTap,
    this.trailing,
    this.readOnly = false,
    this.autofocus = false,
    this.height = 48,
  });

  final String hintText;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onTap;
  final Widget? trailing;
  final bool readOnly;
  final bool autofocus;
  final double height;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    final child = Container(
      height: height,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: palette.stroke),
      ),
      child: Row(
        children: [
          Icon(Icons.search_rounded, size: 22, color: palette.textMuted),
          const SizedBox(width: 10),
          Expanded(
            child: readOnly
                ? Text(
                    hintText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: _credenceFontBody,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: palette.textMuted,
                    ),
                  )
                : TextField(
                    controller: controller,
                    focusNode: focusNode,
                    autofocus: autofocus,
                    onChanged: onChanged,
                    onTap: onTap,
                    decoration: InputDecoration(
                      hintText: hintText,
                      border: InputBorder.none,
                      isDense: true,
                      hintStyle: TextStyle(
                        fontFamily: _credenceFontBody,
                        color: palette.textMuted,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: TextStyle(
                      fontFamily: _credenceFontBody,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: palette.textPrimary,
                    ),
                  ),
          ),
          if (trailing != null) ...[const SizedBox(width: 8), trailing!],
        ],
      ),
    );

    if (!readOnly) return child;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: child,
    );
  }
}

class CredenceBottomNavItem {
  const CredenceBottomNavItem({
    required this.label,
    this.icon,
    IconData? selectedIcon,
    this.iconAsset,
    String? selectedIconAsset,
  }) : selectedIcon = selectedIcon ?? icon,
       selectedIconAsset = selectedIconAsset ?? iconAsset,
       assert(icon != null || iconAsset != null);

  final String label;
  final IconData? icon;
  final IconData? selectedIcon;
  final String? iconAsset;
  final String? selectedIconAsset;
}

class CredenceBottomNav extends StatelessWidget {
  const CredenceBottomNav({
    super.key,
    required this.items,
    required this.activeIndex,
    required this.onTap,
  });

  final List<CredenceBottomNavItem> items;
  final int activeIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    final navColor = palette.surface.withValues(
      alpha: Theme.of(context).brightness == Brightness.dark ? 0.92 : 0.88,
    );

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: navColor,
            border: Border(top: BorderSide(color: palette.stroke, width: 1)),
          ),
          child: SafeArea(
            top: false,
            child: SizedBox(
              height: 66,
              child: Row(
                children: List.generate(items.length, (index) {
                  final selected = index == activeIndex;
                  return Expanded(
                    child: _CredenceBottomNavTile(
                      item: items[index],
                      selected: selected,
                      onTap: () => onTap(index),
                    ),
                  );
                }),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CredenceBottomNavTile extends StatelessWidget {
  const _CredenceBottomNavTile({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final CredenceBottomNavItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    final color = selected ? palette.textPrimary : palette.textMuted;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Semantics(
        selected: selected,
        button: true,
        label: item.label,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _CredenceBottomNavGlyph(
              item: item,
              selected: selected,
              color: color,
            ),
            const SizedBox(height: 3),
            Text(
              item.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: _credenceFontBody,
                fontSize: 9.5,
                height: 1,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                letterSpacing: 0.35,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CredenceBottomNavGlyph extends StatelessWidget {
  const _CredenceBottomNavGlyph({
    required this.item,
    required this.selected,
    required this.color,
  });

  final CredenceBottomNavItem item;
  final bool selected;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final asset = selected ? item.selectedIconAsset : item.iconAsset;
    if (asset != null) {
      return SvgPicture.asset(
        asset,
        width: 22,
        height: 22,
        excludeFromSemantics: true,
        colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
      );
    }

    final icon = (selected ? item.selectedIcon : item.icon) ?? item.icon!;
    return Icon(icon, size: 22, color: color);
  }
}
