import 'package:flutter/material.dart';
import 'package:pass_doc_manager/app/theme/app_palette.dart';

class PrimaryTitleActionBar extends StatelessWidget {
  const PrimaryTitleActionBar({
    super.key,
    required this.title,
    required this.onActionTap,
    this.onBackTap,
    this.backTooltip,
    this.actionIcon = Icons.add_rounded,
    this.titleFontSize = 26,
    this.actionSize = 45,
    this.actionIconSize = 30,
  });

  final String title;
  final VoidCallback onActionTap;
  final VoidCallback? onBackTap;
  final String? backTooltip;
  final IconData actionIcon;
  final double titleFontSize;
  final double actionSize;
  final double actionIconSize;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;

    return Row(
      children: [
        if (onBackTap != null) ...[
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: palette.surfaceSoft,
              borderRadius: BorderRadius.circular(14),
            ),
            child: IconButton(
              tooltip: backTooltip,
              onPressed: onBackTap,
              icon: Icon(
                Icons.arrow_back_ios_new_rounded,
                color: palette.textSecondary,
                size: 24,
              ),
              padding: EdgeInsets.zero,
              splashRadius: 20,
            ),
          ),
          const SizedBox(width: 10),
        ],
        Expanded(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: titleFontSize,
              fontWeight: FontWeight.w700,
              color: palette.textPrimary,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onActionTap,
            borderRadius: BorderRadius.circular(999),
            child: Ink(
              width: actionSize,
              height: actionSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: palette.primary,
                boxShadow: [
                  BoxShadow(
                    color: palette.shadow,
                    blurRadius: 18,
                    offset: const Offset(0, 9),
                  ),
                ],
              ),
              child: Center(
                child: Icon(
                  actionIcon,
                  color: Colors.white,
                  size: actionIconSize,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
