import 'package:flutter/material.dart';
import 'package:pass_doc_manager/app/theme/app_palette.dart';
import 'package:pass_doc_manager/features/home/domain/entities/recent_item_entity.dart';
import 'package:pass_doc_manager/l10n/l10n.dart';

class HomeRecentItemsSection extends StatelessWidget {
  const HomeRecentItemsSection({
    super.key,
    required this.items,
    this.onTap,
  });

  final List<RecentItemEntity> items;
  final ValueChanged<RecentItemEntity>? onTap;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    final palette = context.appPalette;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n.homeRecentActivity,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: palette.textPrimary,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: palette.surface,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: palette.stroke),
          ),
          child: Column(
            children: [
              for (int i = 0; i < (items.length > 6 ? 6 : items.length); i++) ...[
                _RecentRow(
                  item: items[i],
                  onTap: () => onTap?.call(items[i]),
                ),
                if (i < (items.length > 6 ? 5 : items.length - 1))
                  Divider(height: 1, color: palette.stroke),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _RecentRow extends StatelessWidget {
  const _RecentRow({required this.item, this.onTap});

  final RecentItemEntity item;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: _sourceBackground(item.sourceType, palette),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                _sourceIcon(item.sourceType),
                size: 21,
                color: _sourceColor(item.sourceType),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: palette.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _sourceLabel(context, item.sourceType),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: _sourceColor(item.sourceType),
                    ),
                  ),
                ],
              ),
            ),
            Text(
              _timeAgo(item.modifiedAt),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: palette.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _sourceBackground(RecentItemSourceType type, AppPalette palette) {
    switch (type) {
      case RecentItemSourceType.credential:
        return palette.primarySoft;
      case RecentItemSourceType.document:
        return const Color(0xFFE6F8F1);
      case RecentItemSourceType.collection:
        return const Color(0xFFF3EFFF);
    }
  }

  Color _sourceColor(RecentItemSourceType type) {
    switch (type) {
      case RecentItemSourceType.credential:
        return const Color(0xFF3B82F6);
      case RecentItemSourceType.document:
        return const Color(0xFF059669);
      case RecentItemSourceType.collection:
        return const Color(0xFF8B5CF6);
    }
  }

  IconData _sourceIcon(RecentItemSourceType type) {
    switch (type) {
      case RecentItemSourceType.credential:
        return Icons.lock_rounded;
      case RecentItemSourceType.document:
        return Icons.description_rounded;
      case RecentItemSourceType.collection:
        return Icons.folder_special_rounded;
    }
  }

  String _sourceLabel(BuildContext context, RecentItemSourceType type) {
    switch (type) {
      case RecentItemSourceType.credential:
        return context.l10n.homeSourceCredential;
      case RecentItemSourceType.document:
        return context.l10n.homeSourceDocument;
      case RecentItemSourceType.collection:
        return context.l10n.homeSourceCollection;
    }
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${(diff.inDays / 7).floor()}w ago';
  }
}
