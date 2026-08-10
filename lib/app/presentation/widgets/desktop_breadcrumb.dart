import 'package:flutter/material.dart';
import 'package:pass_doc_manager/app/platform/desktop_platform.dart';
import 'package:pass_doc_manager/app/theme/app_palette.dart';

/// A single breadcrumb segment.
class BreadcrumbItem {
  const BreadcrumbItem({
    required this.label,
    this.onTap,
  });

  final String label;
  final VoidCallback? onTap;
}

/// Desktop breadcrumb navigation bar.
/// Shows "Section > Subsection > Current" with clickable ancestors.
/// Hidden on mobile (returns SizedBox.shrink).
class DesktopBreadcrumb extends StatelessWidget {
  const DesktopBreadcrumb({
    super.key,
    required this.items,
  });

  final List<BreadcrumbItem> items;

  @override
  Widget build(BuildContext context) {
    if (!DesktopPlatform.isDesktop || items.isEmpty) {
      return const SizedBox.shrink();
    }

    final palette = context.appPalette;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      child: Row(
        children: [
          for (int i = 0; i < items.length; i++) ...[
            if (i > 0)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Icon(
                  Icons.chevron_right_rounded,
                  size: 16,
                  color: palette.textMuted,
                ),
              ),
            if (i < items.length - 1 && items[i].onTap != null)
              MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: items[i].onTap,
                  child: Text(
                    items[i].label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: palette.primary,
                    ),
                  ),
                ),
              )
            else
              Text(
                items[i].label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: i == items.length - 1
                      ? FontWeight.w700
                      : FontWeight.w500,
                  color: i == items.length - 1
                      ? palette.textPrimary
                      : palette.textSecondary,
                ),
              ),
          ],
        ],
      ),
    );
  }
}
