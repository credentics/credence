import 'dart:io';

import 'package:flutter/material.dart';
import 'package:pass_doc_manager/app/theme/app_palette.dart';
import 'package:pass_doc_manager/core/utils/document_display_resolver.dart';
import 'package:pass_doc_manager/core/utils/local_asset_path_resolver.dart';
import 'package:pass_doc_manager/features/home/domain/entities/quick_access_item_entity.dart';
import 'package:pass_doc_manager/l10n/l10n.dart';

class HomeQuickAccessSection extends StatelessWidget {
  const HomeQuickAccessSection({
    super.key,
    required this.groups,
    this.onItemTap,
  });

  final List<QuickAccessGroupEntity> groups;
  final void Function(String sourceType, String sourceId)? onItemTap;

  @override
  Widget build(BuildContext context) {
    if (groups.isEmpty) return const SizedBox.shrink();

    final palette = context.appPalette;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n.homeQuickAccess,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: palette.textPrimary,
          ),
        ),
        const SizedBox(height: 10),
        for (final group in groups) ...[
          _CollapsibleGroupCard(group: group, onItemTap: onItemTap),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _CollapsibleGroupCard extends StatefulWidget {
  const _CollapsibleGroupCard({required this.group, this.onItemTap});

  final QuickAccessGroupEntity group;
  final void Function(String sourceType, String sourceId)? onItemTap;

  @override
  State<_CollapsibleGroupCard> createState() => _CollapsibleGroupCardState();
}

class _CollapsibleGroupCardState extends State<_CollapsibleGroupCard>
    with SingleTickerProviderStateMixin {
  bool _expanded = false;
  late final AnimationController _controller;
  late final Animation<double> _expandAnimation;
  late final Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
    _rotationAnimation = Tween<double>(
      begin: 0,
      end: 0.5,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() {
      _expanded = !_expanded;
      if (_expanded) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  /// Count leaves (including children of aggregate rows) for the pill badge
  /// so users see the real item count, not the compacted row count.
  int _leafCount() {
    var total = 0;
    for (final item in widget.group.items) {
      total += item.isAggregate ? item.children.length : 1;
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    final color = _groupColor(widget.group.categoryKey, palette);

    return Container(
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: palette.stroke),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          InkWell(
            onTap: _toggle,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _groupIcon(widget.group.categoryKey),
                      size: 19,
                      color: color,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      widget.group.categoryLabel,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: palette.textPrimary,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: palette.surfaceSoft,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${_leafCount()}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: palette.textMuted,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  RotationTransition(
                    turns: _rotationAnimation,
                    child: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 22,
                      color: palette.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizeTransition(
            sizeFactor: _expandAnimation,
            child: Column(
              children: [
                Divider(height: 1, color: palette.stroke),
                for (int i = 0; i < widget.group.items.length; i++) ...[
                  _QuickAccessEntry(
                    item: widget.group.items[i],
                    accent: color,
                    onLeafTap: widget.onItemTap,
                  ),
                  if (i < widget.group.items.length - 1)
                    Divider(height: 1, indent: 58, color: palette.stroke),
                ],
                const SizedBox(height: 4),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _groupColor(String key, AppPalette palette) {
    switch (key) {
      case 'ids':
        return const Color(0xFF3B82F6);
      case 'work':
        return const Color(0xFF8B5CF6);
      case 'documents':
        return const Color(0xFF059669);
      case 'cards':
        return const Color(0xFFD97706);
      case 'collections':
        return const Color(0xFF1152D4);
      case 'tasks':
        return const Color(0xFFEC4899);
      default:
        return palette.primary;
    }
  }

  IconData _groupIcon(String key) {
    switch (key) {
      case 'ids':
        return Icons.fingerprint_rounded;
      case 'work':
        return Icons.work_rounded;
      case 'documents':
        return Icons.description_rounded;
      case 'cards':
        return Icons.credit_card_rounded;
      case 'collections':
        return Icons.collections_bookmark_rounded;
      case 'tasks':
        return Icons.checklist_rounded;
      default:
        return Icons.folder_rounded;
    }
  }
}

/// Renders either a leaf row or an aggregate parent with inline-expandable
/// children. Keeps animation/state isolated so collapsed siblings don't pay
/// for another AnimationController.
class _QuickAccessEntry extends StatefulWidget {
  const _QuickAccessEntry({
    required this.item,
    required this.accent,
    required this.onLeafTap,
  });

  final QuickAccessItemEntity item;
  final Color accent;
  final void Function(String sourceType, String sourceId)? onLeafTap;

  @override
  State<_QuickAccessEntry> createState() => _QuickAccessEntryState();
}

class _QuickAccessEntryState extends State<_QuickAccessEntry> {
  bool _childrenOpen = false;

  @override
  Widget build(BuildContext context) {
    if (!widget.item.isAggregate) {
      return _QuickAccessRow(
        item: widget.item,
        accent: widget.accent,
        onTap: widget.onLeafTap,
      );
    }

    final palette = context.appPalette;
    return Column(
      children: [
        _QuickAccessRow(
          item: widget.item,
          accent: widget.accent,
          onTap: (_, __) =>
              setState(() => _childrenOpen = !_childrenOpen),
          trailing: AnimatedRotation(
            turns: _childrenOpen ? 0.5 : 0,
            duration: const Duration(milliseconds: 180),
            child: Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 20,
              color: palette.textMuted,
            ),
          ),
          countBadge: widget.item.children.length,
        ),
        AnimatedCrossFade(
          crossFadeState: _childrenOpen
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 180),
          firstChild: const SizedBox(width: double.infinity),
          secondChild: Container(
            color: palette.surfaceSoft.withValues(alpha: 0.5),
            child: Column(
              children: [
                for (var i = 0; i < widget.item.children.length; i++) ...[
                  Padding(
                    padding: const EdgeInsets.only(left: 16),
                    child: _QuickAccessRow(
                      item: widget.item.children[i],
                      accent: widget.accent,
                      onTap: widget.onLeafTap,
                      dense: true,
                    ),
                  ),
                  if (i < widget.item.children.length - 1)
                    Divider(
                      height: 1,
                      indent: 74,
                      color: palette.stroke,
                    ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _QuickAccessRow extends StatelessWidget {
  const _QuickAccessRow({
    required this.item,
    required this.accent,
    this.onTap,
    this.trailing,
    this.countBadge,
    this.dense = false,
  });

  final QuickAccessItemEntity item;
  final Color accent;
  final void Function(String sourceType, String sourceId)? onTap;
  final Widget? trailing;
  final int? countBadge;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;

    return InkWell(
      onTap: onTap == null ? null : () => onTap!(item.sourceType, item.sourceId),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: 14,
          vertical: dense ? 8 : 10,
        ),
        child: Row(
          children: [
            _itemIcon(context),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: dense ? 13 : 14,
                      fontWeight: FontWeight.w600,
                      color: palette.textPrimary,
                    ),
                  ),
                  if (_combinedSubtitle().isNotEmpty) ...[
                    const SizedBox(height: 1),
                    Text(
                      _combinedSubtitle(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: dense ? 12 : 13,
                        fontWeight: FontWeight.w500,
                        color: palette.textMuted,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (countBadge != null)
              Container(
                margin: const EdgeInsets.only(right: 6),
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$countBadge',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: accent,
                  ),
                ),
              ),
            trailing ??
                Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: palette.textMuted,
                ),
          ],
        ),
      ),
    );
  }

  String _combinedSubtitle() {
    final parts = <String>[
      if (item.subtitle.isNotEmpty) item.subtitle,
      if (item.dateLabel != null && item.dateLabel!.isNotEmpty) item.dateLabel!,
    ];
    return parts.join(' \u2022 ');
  }

  Widget _itemIcon(BuildContext context) {
    final palette = context.appPalette;
    final size = dense ? 32.0 : 38.0;
    final iconSize = dense ? 16.0 : 18.0;

    final path = item.logoPath;
    final resolvedPath = path == null
        ? null
        : LocalAssetPathResolver.resolveRuntimePathSync(path);
    if (resolvedPath != null &&
        resolvedPath.isNotEmpty &&
        File(resolvedPath).existsSync()) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.file(
          File(resolvedPath),
          width: size,
          height: size,
          fit: BoxFit.cover,
          cacheWidth: (size * 3).round(),
          cacheHeight: (size * 3).round(),
        ),
      );
    }

    final glyph = _iconForKey(item.iconKey, item.sourceType);
    final tone = _iconTone(item.iconKey, item.sourceType, palette, accent);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: tone.$1,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(glyph, size: iconSize, color: tone.$2),
    );
  }
}

IconData _iconForKey(String? key, String sourceType) {
  if (key == null) {
    return _iconForSource(sourceType);
  }
  // Task-list rows carry an icon key prefixed with `task_list_` so the
  // widget can render the list's chosen glyph without depending on the
  // tasks feature package directly.
  if (key.startsWith('task_list_')) {
    final suffix = key.substring('task_list_'.length);
    switch (suffix) {
      case 'flag':
        return Icons.flag_rounded;
      case 'star':
        return Icons.star_rounded;
      case 'home':
        return Icons.home_rounded;
      case 'work':
        return Icons.work_rounded;
      case 'flight':
        return Icons.flight_takeoff_rounded;
      case 'shopping':
        return Icons.shopping_cart_rounded;
      case 'medical':
        return Icons.medical_services_rounded;
      case 'checklist':
      default:
        return Icons.checklist_rounded;
    }
  }
  switch (key) {
    case DocumentIconKey.payslip:
      return Icons.receipt_long_rounded;
    case DocumentIconKey.contract:
      return Icons.assignment_rounded;
    case DocumentIconKey.workRecord:
      return Icons.work_history_rounded;
    case DocumentIconKey.identityCard:
      return Icons.badge_rounded;
    case DocumentIconKey.passport:
      return Icons.flight_takeoff_rounded;
    case DocumentIconKey.driverLicense:
      return Icons.directions_car_rounded;
    case DocumentIconKey.residencePermit:
      return Icons.home_work_rounded;
    case DocumentIconKey.travelTicket:
      return Icons.confirmation_number_rounded;
    case DocumentIconKey.travelTripProfile:
      return Icons.map_rounded;
    case DocumentIconKey.travelBudget:
      return Icons.savings_rounded;
    case DocumentIconKey.travelEvent:
      return Icons.event_rounded;
    case DocumentIconKey.travelExpense:
      return Icons.account_balance_wallet_rounded;
    case DocumentIconKey.propertyRecord:
      return Icons.home_rounded;
    case DocumentIconKey.propertyAsset:
      return Icons.chair_rounded;
    case DocumentIconKey.finance:
      return Icons.payments_rounded;
    case 'credential':
      return Icons.lock_rounded;
    case 'collection':
      return Icons.folder_special_rounded;
    case 'bundle':
      return Icons.folder_zip_rounded;
    case DocumentIconKey.genericDocument:
    default:
      return Icons.description_rounded;
  }
}

IconData _iconForSource(String sourceType) {
  switch (sourceType) {
    case 'credential':
      return Icons.lock_rounded;
    case 'collection':
      return Icons.folder_special_rounded;
    default:
      return Icons.description_rounded;
  }
}

(Color, Color) _iconTone(
  String? key,
  String sourceType,
  AppPalette palette,
  Color accent,
) {
  // Per-icon tinting keeps groups cohesive: background is accent-soft, glyph
  // is a saturated variant. Credentials / collections use their own brand hues.
  switch (key) {
    case 'credential':
      return (palette.primarySoft, const Color(0xFF3B82F6));
    case 'collection':
      return (palette.primarySoft, const Color(0xFF1152D4));
    case 'bundle':
      return (palette.primarySoft, palette.primary);
  }
  return (accent.withValues(alpha: 0.12), accent);
}
