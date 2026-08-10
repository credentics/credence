import 'dart:io';

import 'package:flutter/material.dart';
import 'package:pass_doc_manager/core/utils/local_asset_path_resolver.dart';
import 'package:pass_doc_manager/app/theme/app_palette.dart';
import 'package:pass_doc_manager/features/home/domain/entities/recent_item_entity.dart';
import 'package:pass_doc_manager/l10n/l10n.dart';

class HomeFrequentlyUsedSection extends StatelessWidget {
  const HomeFrequentlyUsedSection({super.key, required this.items, this.onTap});

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
          context.l10n.homeFrequentlyUsed,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: palette.textPrimary,
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 116,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final item = items[index];
              return _FrequentItem(item: item, onTap: () => onTap?.call(item));
            },
          ),
        ),
      ],
    );
  }
}

class _FrequentItem extends StatelessWidget {
  const _FrequentItem({required this.item, this.onTap});

  final RecentItemEntity item;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;

    return Material(
      color: palette.surface,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          width: 110,
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: palette.stroke),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _itemAvatar(),
              const SizedBox(height: 8),
              Text(
                item.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: palette.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                item.subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: palette.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _itemAvatar() {
    final path = item.previewImagePath;
    final resolvedPath = path == null
        ? null
        : LocalAssetPathResolver.resolveRuntimePathSync(path);
    if (resolvedPath != null &&
        resolvedPath.isNotEmpty &&
        File(resolvedPath).existsSync()) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Image.file(
          File(resolvedPath),
          width: 44,
          height: 44,
          fit: BoxFit.cover,
          cacheWidth: 132,
          cacheHeight: 132,
        ),
      );
    }

    final isCredential = item.sourceType == RecentItemSourceType.credential;

    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: isCredential ? const Color(0xFFEAF0FF) : const Color(0xFFE6F8F1),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(
        isCredential ? Icons.lock_rounded : Icons.description_rounded,
        size: 22,
        color: isCredential ? const Color(0xFF3B82F6) : const Color(0xFF059669),
      ),
    );
  }
}
