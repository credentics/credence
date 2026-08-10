import 'package:flutter/material.dart';
import 'package:pass_doc_manager/app/theme/app_palette.dart';
import 'package:pass_doc_manager/domain/bundles/entities/bundle_item_ref.dart';
import 'package:pass_doc_manager/domain/bundles/entities/bundle_item_type.dart';
import 'package:pass_doc_manager/features/bundles/presentation/support/bundle_relative_time.dart';
import 'package:pass_doc_manager/l10n/l10n.dart';

class BundleItemTile extends StatelessWidget {
  const BundleItemTile({
    super.key,
    required this.item,
    this.onRemove,
    this.onTap,
  });

  final BundleItemRef item;
  final VoidCallback? onRemove;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    final accent = _accentColor(palette, item.type);
    return Material(
      color: palette.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: palette.strokeStrong.withValues(alpha: 0.7)),
      ),
      elevation: 0,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 12, 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _TypeIcon(type: item.type, accent: accent),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _InfoChip(
                          icon: _typeGlyph(item.type),
                          label: _typeLabel(item.type),
                          palette: palette,
                          color: accent,
                        ),
                        _InfoChip(
                          icon: Icons.schedule_rounded,
                          label: formatBundleRelative(
                            item.addedAt,
                            context.l10n,
                          ),
                          palette: palette,
                          color: palette.textMuted,
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      item.displayName,
                      style: TextStyle(
                        color: palette.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        height: 1.15,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                    ),
                    if (item.subtitle != null && item.subtitle!.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        item.subtitle!,
                        style: TextStyle(
                          color: palette.textSecondary,
                          fontSize: 13,
                          height: 1.25,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                children: [
                  if (onRemove != null) ...[
                    _IconCircleButton(
                      tooltip: MaterialLocalizations.of(
                        context,
                      ).deleteButtonTooltip,
                      icon: Icons.close_rounded,
                      foregroundColor: palette.textMuted,
                      backgroundColor: palette.surfaceSoft,
                      onPressed: onRemove!,
                    ),
                    const SizedBox(height: 10),
                  ],
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      Icons.arrow_outward_rounded,
                      size: 18,
                      color: accent,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TypeIcon extends StatelessWidget {
  const _TypeIcon({required this.type, required this.accent});

  final BundleItemType type;
  final Color accent;

  IconData get _icon {
    return _typeGlyph(type);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accent.withValues(alpha: 0.18),
            accent.withValues(alpha: 0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withValues(alpha: 0.18)),
      ),
      alignment: Alignment.center,
      child: Icon(_icon, size: 24, color: accent),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.icon,
    required this.label,
    required this.palette,
    required this.color,
  });

  final IconData icon;
  final String label;
  final AppPalette palette;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: palette.surfaceSoft,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: palette.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _IconCircleButton extends StatelessWidget {
  const _IconCircleButton({
    required this.tooltip,
    required this.icon,
    required this.foregroundColor,
    required this.backgroundColor,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final Color foregroundColor;
  final Color backgroundColor;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: backgroundColor,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: Tooltip(
          message: tooltip,
          child: SizedBox(
            width: 34,
            height: 34,
            child: Icon(icon, size: 18, color: foregroundColor),
          ),
        ),
      ),
    );
  }
}

Color _accentColor(AppPalette palette, [BundleItemType? type]) {
  switch (type) {
    case BundleItemType.credential:
      return palette.primaryAccent;
    case BundleItemType.document:
      return palette.primary;
    case BundleItemType.note:
      return palette.success;
    case BundleItemType.identityCard:
      return palette.warning;
    case BundleItemType.collection:
      return palette.textSecondary;
    case null:
      return palette.primary;
  }
}

IconData _typeGlyph(BundleItemType type) {
  switch (type) {
    case BundleItemType.credential:
      return Icons.key_rounded;
    case BundleItemType.document:
      return Icons.description_rounded;
    case BundleItemType.note:
      return Icons.sticky_note_2_rounded;
    case BundleItemType.identityCard:
      return Icons.badge_rounded;
    case BundleItemType.collection:
      return Icons.folder_rounded;
  }
}

String _typeLabel(BundleItemType type) {
  switch (type) {
    case BundleItemType.credential:
      return 'Credential';
    case BundleItemType.document:
      return 'Document';
    case BundleItemType.note:
      return 'Note';
    case BundleItemType.identityCard:
      return 'Identity';
    case BundleItemType.collection:
      return 'Collection';
  }
}
