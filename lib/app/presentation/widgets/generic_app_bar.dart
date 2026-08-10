import 'package:flutter/material.dart';
import 'package:pass_doc_manager/app/theme/app_palette.dart';

class GenericAppBar extends StatelessWidget implements PreferredSizeWidget {
  static const double _kToolbarHeight = 60;
  static const double _kLeadingWidth = 55;
  static const double _kBackIconSize = 18;
  static const double _kActionIconSize = 24;

  const GenericAppBar({
    super.key,
    this.title,
    this.titleWidget,
    this.centerTitle = true,
    this.titleStyle,
    this.titleSpacing,
    this.backgroundColor,
    this.titleColor,
    this.showBackButton = true,
    this.onBackPressed,
    this.backIcon = Icons.arrow_back_ios_new_rounded,
    this.backTooltip,
    this.leading,
    this.actionIcon,
    this.onActionPressed,
    this.actionTooltip,
    this.actions,
    this.iconColor,
    this.iconBackgroundColor,
    this.showDivider = true,
    this.bottom,
    this.automaticallyImplyLeading = false,
  });

  final String? title;
  final Widget? titleWidget;
  final bool centerTitle;
  final TextStyle? titleStyle;
  final double? titleSpacing;
  final Color? backgroundColor;
  final Color? titleColor;
  final bool showBackButton;
  final VoidCallback? onBackPressed;
  final IconData backIcon;
  final String? backTooltip;
  final Widget? leading;
  final IconData? actionIcon;
  final VoidCallback? onActionPressed;
  final String? actionTooltip;
  final List<Widget>? actions;
  final Color? iconColor;
  final Color? iconBackgroundColor;
  final bool showDivider;
  final PreferredSizeWidget? bottom;
  final bool automaticallyImplyLeading;

  @override
  Size get preferredSize => Size.fromHeight(
    _kToolbarHeight + (bottom?.preferredSize.height ?? (showDivider ? 1 : 0)),
  );

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    final resolvedBg = backgroundColor ?? palette.surface;
    final resolvedIconColor = iconColor ?? palette.textPrimary;
    final resolvedIconBg = iconBackgroundColor ?? palette.surfaceSoft;
    final resolvedTitleColor = titleColor ?? palette.textPrimary;

    final resolvedLeading = leading ?? _buildLeading(resolvedIconColor, resolvedIconBg);
    final resolvedActions = actions ?? _buildSingleAction(resolvedIconColor, resolvedIconBg);

    return AppBar(
      backgroundColor: resolvedBg,
      surfaceTintColor: Colors.transparent,
      automaticallyImplyLeading: automaticallyImplyLeading,
      toolbarHeight: _kToolbarHeight,
      leading: resolvedLeading,
      leadingWidth: resolvedLeading == null ? null : _kLeadingWidth,
      titleSpacing: titleSpacing,
      centerTitle: centerTitle,
      title: titleWidget ?? _buildTitle(resolvedTitleColor),
      actions: resolvedActions,
      bottom:
          bottom ??
          (showDivider
              ? PreferredSize(
                  preferredSize: const Size.fromHeight(1),
                  child: Divider(height: 1, color: palette.strokeStrong),
                )
              : null),
    );
  }

  Widget? _buildLeading(Color resolvedIconColor, Color resolvedIconBg) {
    if (!showBackButton) {
      return null;
    }
    return Padding(
      padding: const EdgeInsets.only(left: 10, top: 8, bottom: 8),
      child: _SquareIconButton(
        icon: backIcon,
        onPressed: onBackPressed,
        tooltip: backTooltip,
        iconColor: resolvedIconColor,
        backgroundColor: resolvedIconBg,
        iconSize: _kBackIconSize,
      ),
    );
  }

  List<Widget>? _buildSingleAction(Color resolvedIconColor, Color resolvedIconBg) {
    if (actionIcon == null) {
      return null;
    }
    return [
      Padding(
        padding: const EdgeInsets.only(right: 10, top: 8, bottom: 8),
        child: _SquareIconButton(
          icon: actionIcon!,
          onPressed: onActionPressed,
          tooltip: actionTooltip,
          iconColor: resolvedIconColor,
          backgroundColor: resolvedIconBg,
          iconSize: _kActionIconSize,
        ),
      ),
    ];
  }

  Widget? _buildTitle(Color resolvedTitleColor) {
    final value = (title ?? '').trim();
    if (value.isEmpty) {
      return null;
    }
    return Text(
      value,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style:
          titleStyle ??
          TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: resolvedTitleColor,
          ),
    );
  }
}

class _SquareIconButton extends StatelessWidget {
  const _SquareIconButton({
    required this.icon,
    required this.onPressed,
    required this.iconColor,
    required this.backgroundColor,
    required this.iconSize,
    this.tooltip,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final Color iconColor;
  final Color backgroundColor;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final disabled = onPressed == null;
    final button = Opacity(
      opacity: disabled ? 0.45 : 1,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(18),
          child: Ink(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(icon, size: iconSize, color: iconColor),
          ),
        ),
      ),
    );
    final message = (tooltip ?? '').trim();
    if (message.isEmpty) {
      return button;
    }
    return Tooltip(
      message: message,
      waitDuration: const Duration(milliseconds: 450),
      child: button,
    );
  }
}
