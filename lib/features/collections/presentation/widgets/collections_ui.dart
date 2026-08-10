import 'dart:math' as math;

import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/material.dart';
import 'package:pass_doc_manager/core/utils/local_asset_path_resolver.dart';
import 'package:pass_doc_manager/core/utils/local_file_image_provider.dart';
import 'package:pass_doc_manager/app/theme/app_palette.dart';
import 'package:pass_doc_manager/domain/collections/entities/collection_block_entity.dart';
import 'package:pass_doc_manager/domain/collections/entities/collection_block_metadata_keys.dart';
import 'package:pass_doc_manager/domain/collections/entities/collection_block_type.dart';
import 'package:pass_doc_manager/app/presentation/widgets/adaptive_modal.dart';
import 'package:pass_doc_manager/l10n/l10n.dart';

const Color collectionsPrimary = Color(0xFF1152D4);
const Color collectionsBackground = Color(0xFFF6F6F8);
const Color collectionsCardBorder = Color(0xFFE4EAF4);
const Color collectionsCardShadow = Color(0x10124C9C);

String normalizeCollectionEmoji(String? raw) {
  final input = (raw ?? '').trim();
  if (input.isEmpty) {
    return '';
  }
  for (final cluster in input.characters) {
    final candidate = cluster.trim();
    if (candidate.isEmpty) {
      continue;
    }
    if (_looksLikeEmojiCluster(candidate)) {
      return candidate;
    }
  }
  return '';
}

bool _looksLikeEmojiCluster(String cluster) {
  var hasEmojiCodePoint = false;
  for (final codePoint in cluster.runes) {
    if (codePoint == 0x200D || codePoint == 0xFE0F || codePoint == 0x20E3) {
      return true;
    }
    if (_isEmojiCodePoint(codePoint)) {
      hasEmojiCodePoint = true;
    }
  }
  return hasEmojiCodePoint;
}

bool _isEmojiCodePoint(int codePoint) {
  return (codePoint >= 0x1F000 && codePoint <= 0x1FAFF) ||
      (codePoint >= 0x2600 && codePoint <= 0x27BF) ||
      (codePoint >= 0x2300 && codePoint <= 0x23FF);
}

class CollectionsSurfaceCard extends StatelessWidget {
  const CollectionsSurfaceCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(14),
    this.radius = 18,
    this.backgroundColor,
    this.borderColor,
    this.showShadow = false,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final Color? backgroundColor;
  final Color? borderColor;
  final bool showShadow;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor ?? palette.surface,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color:
              borderColor ??
              palette.stroke.withValues(alpha: isDark ? 0.72 : 0.9),
        ),
        boxShadow: showShadow
            ? [
                BoxShadow(
                  color: palette.shadow.withValues(alpha: isDark ? 0.16 : 1),
                  blurRadius: isDark ? 10 : 18,
                  offset: const Offset(0, 5),
                ),
              ]
            : const [],
      ),
      child: child,
    );
  }
}

class CollectionsSectionLabel extends StatelessWidget {
  const CollectionsSectionLabel({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w800,
        fontFamily: 'JetBrains Mono',
        letterSpacing: 1.4,
        color: context.appPalette.textMuted,
      ),
    );
  }
}

class CollectionsPrimaryButton extends StatelessWidget {
  const CollectionsPrimaryButton({
    super.key,
    required this.label,
    this.icon,
    required this.onPressed,
  });

  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final disabled = onPressed == null;
    final palette = context.appPalette;
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: icon == null
            ? const SizedBox.shrink()
            : Icon(icon, size: 20, color: Colors.white),
        label: Text(
          label,
          style: const TextStyle(
            fontSize: 23 / 1.45,
            fontWeight: FontWeight.w800,
          ),
        ),
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: disabled ? palette.surfaceSoft : collectionsPrimary,
          foregroundColor: disabled ? palette.textMuted : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
        ),
      ),
    );
  }
}

class CollectionsDashedOutline extends StatelessWidget {
  const CollectionsDashedOutline({
    super.key,
    required this.child,
    this.color,
    this.radius = 18,
    this.strokeWidth = 1.4,
    this.dashLength = 6,
    this.gapLength = 5,
  });

  final Widget child;
  final Color? color;
  final double radius;
  final double strokeWidth;
  final double dashLength;
  final double gapLength;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DashedRoundedBorderPainter(
        color: color ?? context.appPalette.stroke,
        strokeWidth: strokeWidth,
        radius: radius,
        dashLength: dashLength,
        gapLength: gapLength,
      ),
      child: child,
    );
  }
}

class CollectionsChecklistPreviewCard extends StatelessWidget {
  const CollectionsChecklistPreviewCard({
    super.key,
    required this.block,
    required this.onTap,
    this.onLongPress,
    this.onToggleItem,
    this.radius = 18,
    this.maxPreviewItems = 5,
  });

  final CollectionBlockEntity block;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final ValueChanged<int>? onToggleItem;
  final double radius;
  final int maxPreviewItems;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    final items = block.checklistItems;
    final total = items.length;
    final done = items.where((item) => item.isDone).length;
    final progress = total == 0 ? 0.0 : (done / total).clamp(0.0, 1.0);
    final visibleItems = items.take(maxPreviewItems).toList(growable: false);
    final description = block.description
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      borderRadius: BorderRadius.circular(radius),
      child: CollectionsSurfaceCard(
        radius: radius,
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                buildCollectionBlockLeadingIcon(
                  context,
                  type: CollectionBlockType.checklist,
                  metadata: block.metadata,
                  shellSize: 42,
                  shellRadius: 13,
                  iconSize: 22,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    block.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w800,
                      color: palette.textPrimary,
                      height: 1.1,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 13,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: palette.surfaceSoft,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '$done of $total',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                      fontFamily: 'JetBrains Mono',
                      color: palette.textPrimary,
                      height: 1,
                    ),
                  ),
                ),
              ],
            ),
            if (description.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.32,
                  fontWeight: FontWeight.w500,
                  color: palette.textSecondary,
                ),
              ),
            ],
            if (visibleItems.isNotEmpty) ...[
              const SizedBox(height: 15),
              for (var index = 0; index < visibleItems.length; index++)
                _ChecklistPreviewItemRow(
                  itemIndex: index,
                  title: visibleItems[index].title,
                  isDone: visibleItems[index].isDone,
                  showDivider: index != visibleItems.length - 1,
                  onToggle: onToggleItem == null
                      ? null
                      : () => onToggleItem!(index),
                ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 5,
                  backgroundColor: palette.stroke.withValues(alpha: 0.7),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    palette.textPrimary,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ChecklistPreviewItemRow extends StatelessWidget {
  const _ChecklistPreviewItemRow({
    required this.itemIndex,
    required this.title,
    required this.isDone,
    required this.showDivider,
    this.onToggle,
  });

  final int itemIndex;
  final String title;
  final bool isDone;
  final bool showDivider;
  final VoidCallback? onToggle;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    return Column(
      children: [
        Row(
          children: [
            Semantics(
              button: true,
              checked: isDone,
              label: title,
              child: InkWell(
                onTap: onToggle,
                borderRadius: BorderRadius.circular(7),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: isDone ? palette.textPrimary : Colors.transparent,
                    borderRadius: BorderRadius.circular(7),
                    border: Border.all(
                      color: isDone
                          ? palette.textPrimary
                          : palette.stroke.withValues(alpha: 0.9),
                      width: 1.5,
                    ),
                  ),
                  child: isDone
                      ? Icon(
                          Icons.check_rounded,
                          size: 16,
                          color: palette.background,
                        )
                      : null,
                ),
              ),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w600,
                  color: isDone ? palette.textMuted : palette.textPrimary,
                  decoration: isDone
                      ? TextDecoration.lineThrough
                      : TextDecoration.none,
                  decorationColor: palette.textMuted,
                  decorationThickness: 1.7,
                  height: 1.25,
                ),
              ),
            ),
          ],
        ),
        if (showDivider)
          Padding(
            padding: const EdgeInsets.only(left: 37, top: 10, bottom: 10),
            child: Divider(
              height: 1,
              thickness: 1,
              color: palette.stroke.withValues(alpha: 0.7),
            ),
          ),
      ],
    );
  }
}

class CollectionsProgressPreviewCard extends StatelessWidget {
  const CollectionsProgressPreviewCard({
    super.key,
    required this.block,
    required this.onTap,
    this.onLongPress,
    this.radius = 18,
  });

  final CollectionBlockEntity block;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    final current = block.amount ?? 0;
    final target = _parseProgressNumber(block.metadata['target_amount']);
    final ratio = target > 0
        ? (current / target).clamp(0.0, 1.0).toDouble()
        : 0.0;
    final percent = (ratio * 100).round();
    final unit = (block.metadata['unit'] ?? '').trim();
    final title = block.title.trim().isEmpty
        ? context.l10n.collectionBlockProgress.toUpperCase()
        : block.title.trim().toUpperCase();
    final description = block.description
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      borderRadius: BorderRadius.circular(radius),
      child: CollectionsSurfaceCard(
        radius: radius,
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    'PROGRESS · $title',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'JetBrains Mono',
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2.2,
                      color: palette.textSecondary,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  '$percent%',
                  style: TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 17,
                    height: 1,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.2,
                    color: palette.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Flexible(
                  flex: 0,
                  child: Text(
                    _formatProgressAmount(current, unit),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 27,
                      height: 0.98,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.8,
                      color: palette.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: Text(
                      '/ ${_formatProgressAmount(target, unit)} target',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: 15,
                        height: 1.05,
                        fontWeight: FontWeight.w500,
                        letterSpacing: -0.2,
                        color: palette.textSecondary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: ratio,
                minHeight: 5,
                backgroundColor: palette.stroke.withValues(alpha: 0.7),
                valueColor: AlwaysStoppedAnimation<Color>(
                  ratio >= 1.0 ? palette.success : palette.textPrimary,
                ),
              ),
            ),
            if (description.isNotEmpty) ...[
              const SizedBox(height: 9),
              Text(
                description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 13,
                  height: 1.3,
                  fontWeight: FontWeight.w500,
                  color: palette.textSecondary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

double _parseProgressNumber(String? raw) {
  final normalized = (raw ?? '').replaceAll(',', '').trim();
  if (normalized.isEmpty) {
    return 0;
  }
  return double.tryParse(normalized) ?? 0;
}

String _formatProgressAmount(double value, String unit) {
  final compact = _compactProgressNumber(value);
  final normalizedUnit = unit.trim();
  if (normalizedUnit.isEmpty) {
    return compact;
  }
  return switch (normalizedUnit) {
    r'$' || '€' || '£' || '¥' || '₩' || '₹' => '$normalizedUnit$compact',
    'USD' => '\$$compact',
    'EUR' => '€$compact',
    'GBP' => '£$compact',
    'JPY' => '¥$compact',
    '%' => '$compact%',
    _ => '$compact $normalizedUnit',
  };
}

String _compactProgressNumber(double value) {
  final absolute = value.abs();
  if (absolute >= 1000000000) {
    return '${_trimProgressNumber(value / 1000000000)}B';
  }
  if (absolute >= 1000000) {
    return '${_trimProgressNumber(value / 1000000)}M';
  }
  if (absolute >= 1000) {
    return '${_trimProgressNumber(value / 1000)}k';
  }
  return _trimProgressNumber(value);
}

String _trimProgressNumber(double value) {
  if (value == value.roundToDouble()) {
    return value.toStringAsFixed(0);
  }
  return value.toStringAsFixed(1).replaceFirst(RegExp(r'\.0$'), '');
}

class CollectionsDashedUploadZone extends StatefulWidget {
  const CollectionsDashedUploadZone({
    super.key,
    required this.title,
    required this.subtitle,
    this.buttonLabel,
    this.onTap,
    this.onFileDrop,
    this.icon = Icons.cloud_upload_rounded,
  });

  final String title;
  final String subtitle;
  final String? buttonLabel;
  final VoidCallback? onTap;
  final ValueChanged<String>? onFileDrop;
  final IconData icon;

  @override
  State<CollectionsDashedUploadZone> createState() =>
      _CollectionsDashedUploadZoneState();
}

class _CollectionsDashedUploadZoneState
    extends State<CollectionsDashedUploadZone> {
  bool _isDragging = false;

  bool get _isDesktop {
    final platform = Theme.of(context).platform;
    return platform == TargetPlatform.macOS ||
        platform == TargetPlatform.windows ||
        platform == TargetPlatform.linux;
  }

  @override
  Widget build(BuildContext context) {
    final zone = _buildZone(context);
    if (!_isDesktop || widget.onFileDrop == null) return zone;

    return DropTarget(
      onDragEntered: (_) => setState(() => _isDragging = true),
      onDragExited: (_) => setState(() => _isDragging = false),
      onDragDone: (details) {
        setState(() => _isDragging = false);
        final files = details.files;
        if (files.isNotEmpty) {
          widget.onFileDrop!(files.first.path);
        }
      },
      child: zone,
    );
  }

  Widget _buildZone(BuildContext context) {
    final borderColor = _isDragging
        ? collectionsPrimary
        : const Color(0xFFB8CCF6);
    final bgColor = _isDragging
        ? collectionsPrimary.withValues(alpha: 0.06)
        : context.appPalette.surfaceSoft;

    return InkWell(
      onTap: widget.onTap,
      borderRadius: BorderRadius.circular(24),
      child: CustomPaint(
        painter: _DashedRoundedBorderPainter(
          color: borderColor,
          strokeWidth: _isDragging ? 2.5 : 1.5,
          radius: 24,
          dashLength: 8,
          gapLength: 5,
        ),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 26),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            children: [
              Container(
                width: 78,
                height: 78,
                decoration: BoxDecoration(
                  color: context.appPalette.primarySoft,
                  borderRadius: BorderRadius.circular(24),
                ),
                alignment: Alignment.center,
                child: Icon(
                  _isDragging ? Icons.file_download_rounded : widget.icon,
                  color: collectionsPrimary,
                  size: 36,
                ),
              ),
              SizedBox(height: 14),
              Text(
                _isDragging
                    ? context.l10n.collectionUploadDropHere
                    : widget.title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24 / 1.45,
                  fontWeight: FontWeight.w800,
                  color: context.appPalette.textPrimary,
                ),
              ),
              SizedBox(height: 6),
              Text(
                _isDragging ? '' : widget.subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: context.appPalette.textSecondary,
                ),
              ),
              if (!_isDragging &&
                  (widget.buttonLabel ?? '').trim().isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 9,
                  ),
                  decoration: BoxDecoration(
                    color: collectionsPrimary,
                    borderRadius: BorderRadius.circular(999),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x301152D4),
                        blurRadius: 12,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Text(
                    widget.buttonLabel!,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class CollectionsBlockOption {
  const CollectionsBlockOption({
    required this.type,
    required this.title,
    required this.description,
    required this.icon,
    required this.background,
    required this.foreground,
  });

  final CollectionBlockType type;
  final String title;
  final String description;
  final IconData icon;
  final Color background;
  final Color foreground;
}

List<CollectionsBlockOption> defaultCollectionsBlockOptions(
  BuildContext context,
) {
  return [
    CollectionsBlockOption(
      type: CollectionBlockType.folder,
      title: context.l10n.collectionBlockFolder,
      description: context.l10n.collectionBlockFolderDesc,
      icon: Icons.folder_rounded,
      background: const Color(0xFFE8EEFF),
      foreground: const Color(0xFF2A5CD6),
    ),
    CollectionsBlockOption(
      type: CollectionBlockType.section,
      title: context.l10n.collectionBlockSection,
      description: context.l10n.collectionBlockSectionDesc,
      icon: Icons.view_agenda_rounded,
      background: const Color(0xFFE8ECF4),
      foreground: const Color(0xFF5C6F8A),
    ),
    CollectionsBlockOption(
      type: CollectionBlockType.document,
      title: context.l10n.collectionBlockDocument,
      description: context.l10n.collectionBlockDocumentDesc,
      icon: Icons.description_rounded,
      background: const Color(0xFFFCEFD9),
      foreground: const Color(0xFFE79D17),
    ),
    CollectionsBlockOption(
      type: CollectionBlockType.note,
      title: context.l10n.collectionBlockNote,
      description: context.l10n.collectionBlockNoteDesc,
      icon: Icons.notes_rounded,
      background: const Color(0xFFE7F8F2),
      foreground: const Color(0xFF1CB883),
    ),
    CollectionsBlockOption(
      type: CollectionBlockType.input,
      title: context.l10n.collectionBlockInput,
      description: context.l10n.collectionBlockInputDesc,
      icon: Icons.input_rounded,
      background: const Color(0xFFEFF2F7),
      foreground: const Color(0xFF7486A2),
    ),
    CollectionsBlockOption(
      type: CollectionBlockType.checklist,
      title: context.l10n.collectionBlockChecklist,
      description: context.l10n.collectionBlockChecklistDesc,
      icon: Icons.checklist_rounded,
      background: const Color(0xFFEFEBFF),
      foreground: const Color(0xFF7A67E8),
    ),
    CollectionsBlockOption(
      type: CollectionBlockType.link,
      title: context.l10n.collectionBlockLink,
      description: context.l10n.collectionBlockLinkDesc,
      icon: Icons.link_rounded,
      background: const Color(0xFFE3F6FB),
      foreground: const Color(0xFF25A8D8),
    ),
    CollectionsBlockOption(
      type: CollectionBlockType.image,
      title: context.l10n.collectionBlockImage,
      description: context.l10n.collectionBlockImageDesc,
      icon: Icons.image_rounded,
      background: const Color(0xFFFFE8F0),
      foreground: const Color(0xFFEC5F84),
    ),
    CollectionsBlockOption(
      type: CollectionBlockType.expense,
      title: context.l10n.collectionBlockExpense,
      description: context.l10n.collectionBlockExpenseDesc,
      icon: Icons.payments_rounded,
      background: const Color(0xFFE8FAEF),
      foreground: const Color(0xFF18A763),
    ),
    CollectionsBlockOption(
      type: CollectionBlockType.timeline,
      title: context.l10n.collectionBlockTimeline,
      description: context.l10n.collectionBlockTimelineDesc,
      icon: Icons.timeline_rounded,
      background: const Color(0xFFFFF1E7),
      foreground: const Color(0xFFF0892A),
    ),
    CollectionsBlockOption(
      type: CollectionBlockType.location,
      title: context.l10n.collectionBlockLocation,
      description: context.l10n.collectionBlockLocationDesc,
      icon: Icons.place_rounded,
      background: const Color(0xFFE8F1FF),
      foreground: const Color(0xFF3C79EC),
    ),
    CollectionsBlockOption(
      type: CollectionBlockType.reminder,
      title: context.l10n.collectionBlockReminder,
      description: context.l10n.collectionBlockReminderDesc,
      icon: Icons.notifications_rounded,
      background: const Color(0xFFFFF3E0),
      foreground: const Color(0xFFE8890C),
    ),
    CollectionsBlockOption(
      type: CollectionBlockType.progress,
      title: context.l10n.collectionBlockProgress,
      description: context.l10n.collectionBlockProgressDesc,
      icon: Icons.donut_small_rounded,
      background: const Color(0xFFE8F0FF),
      foreground: const Color(0xFF3B6DE8),
    ),
  ];
}

Future<CollectionBlockType?> showCollectionsAddBlockSheet(
  BuildContext context, {
  Set<CollectionBlockType> excludeTypes = const {},
}) {
  final options = defaultCollectionsBlockOptions(
    context,
  ).where((o) => !excludeTypes.contains(o.type)).toList();
  return showAdaptiveModal<CollectionBlockType>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      final palette = context.appPalette;
      return Container(
        margin: const EdgeInsets.only(top: 88),
        decoration: BoxDecoration(
          color: palette.background,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Builder(
          builder: (context) {
            final structural = options
                .where(
                  (option) =>
                      option.type == CollectionBlockType.folder ||
                      option.type == CollectionBlockType.section,
                )
                .toList(growable: false);
            final content =
                options
                    .where(
                      (option) =>
                          option.type != CollectionBlockType.folder &&
                          option.type != CollectionBlockType.section,
                    )
                    .toList(growable: false)
                  ..sort(
                    (a, b) => _blockPickerOrder(
                      a.type,
                    ).compareTo(_blockPickerOrder(b.type)),
                  );

            return SafeArea(
              top: false,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.sizeOf(context).height * 0.9,
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(28, 18, 28, 18),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 36,
                          height: 4,
                          decoration: BoxDecoration(
                            color: palette.stroke,
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          SizedBox(
                            width: 64,
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: TextButton(
                                onPressed: () => Navigator.of(context).pop(),
                                style: TextButton.styleFrom(
                                  foregroundColor: palette.textSecondary,
                                  padding: EdgeInsets.zero,
                                  minimumSize: const Size(58, 40),
                                ),
                                child: Text(
                                  context.l10n.commonCancel,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              context.l10n.collectionAddBlockTitle,
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.2,
                                color: palette.textPrimary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 64),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Flexible(
                        child: ListView(
                          shrinkWrap: true,
                          padding: EdgeInsets.zero,
                          children: [
                            if (structural.isNotEmpty) ...[
                              CollectionsSectionLabel(
                                label:
                                    context.l10n.collectionAddBlockStructural,
                              ),
                              const SizedBox(height: 8),
                              GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: structural.length,
                                padding: EdgeInsets.zero,
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 2,
                                      crossAxisSpacing: 8,
                                      mainAxisSpacing: 8,
                                      childAspectRatio: 3.05,
                                    ),
                                itemBuilder: (context, index) {
                                  return _CollectionsAddBlockMiniTile(
                                    option: structural[index],
                                  );
                                },
                              ),
                              const SizedBox(height: 14),
                            ],
                            if (content.isNotEmpty) ...[
                              CollectionsSectionLabel(
                                label:
                                    '${context.l10n.collectionAddBlockContent} · ${content.length}',
                              ),
                              const SizedBox(height: 8),
                              GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: content.length,
                                padding: EdgeInsets.zero,
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 3,
                                      crossAxisSpacing: 8,
                                      mainAxisSpacing: 8,
                                      childAspectRatio: 1.28,
                                    ),
                                itemBuilder: (context, index) {
                                  return _CollectionsAddBlockTile(
                                    option: content[index],
                                  );
                                },
                              ),
                              const SizedBox(height: 8),
                              _CollectionsMoreBlockTile(palette: palette),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      );
    },
  );
}

int _blockPickerOrder(CollectionBlockType type) {
  return switch (type) {
    CollectionBlockType.document => 0,
    CollectionBlockType.image => 1,
    CollectionBlockType.note => 2,
    CollectionBlockType.input => 3,
    CollectionBlockType.checklist => 4,
    CollectionBlockType.link => 5,
    CollectionBlockType.expense => 6,
    CollectionBlockType.timeline => 7,
    CollectionBlockType.location => 8,
    CollectionBlockType.reminder => 9,
    CollectionBlockType.progress => 10,
    CollectionBlockType.folder => 20,
    CollectionBlockType.section => 21,
  };
}

IconData _blockPickerIcon(CollectionBlockType type) {
  return switch (type) {
    CollectionBlockType.folder => Icons.folder_outlined,
    CollectionBlockType.section => Icons.format_list_bulleted_rounded,
    CollectionBlockType.document => Icons.article_outlined,
    CollectionBlockType.image => Icons.image_outlined,
    CollectionBlockType.note => Icons.feed_outlined,
    CollectionBlockType.input => Icons.input_rounded,
    CollectionBlockType.checklist => Icons.checklist_rounded,
    CollectionBlockType.link => Icons.link_rounded,
    CollectionBlockType.expense => Icons.control_camera_rounded,
    CollectionBlockType.timeline => Icons.calendar_month_outlined,
    CollectionBlockType.location => Icons.location_on_outlined,
    CollectionBlockType.reminder => Icons.schedule_rounded,
    CollectionBlockType.progress => Icons.trending_up_rounded,
  };
}

class _CollectionsAddBlockMiniTile extends StatelessWidget {
  const _CollectionsAddBlockMiniTile({required this.option});

  final CollectionsBlockOption option;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? palette.surfaceSoft : const Color(0xFFF6F4F1);
    final fg = palette.textPrimary;
    return InkWell(
      onTap: () => Navigator.of(context).pop(option.type),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(_blockPickerIcon(option.type), size: 20, color: fg),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                option.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.1,
                  color: fg,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CollectionsAddBlockTile extends StatelessWidget {
  const _CollectionsAddBlockTile({required this.option});

  final CollectionsBlockOption option;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: () => Navigator.of(context).pop(option.type),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.fromLTRB(6, 14, 6, 10),
        decoration: BoxDecoration(
          color: isDark ? palette.surfaceSoft : const Color(0xFFF6F4F1),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _blockPickerIcon(option.type),
              size: 22,
              color: palette.textPrimary,
            ),
            const SizedBox(height: 7),
            Text(
              option.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.05,
                color: palette.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CollectionsMoreBlockTile extends StatelessWidget {
  const _CollectionsMoreBlockTile({required this.palette});

  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        width: (MediaQuery.sizeOf(context).width - 72) / 3,
        height: 86,
        decoration: BoxDecoration(
          color: (isDark ? palette.surfaceSoft : const Color(0xFFF6F4F1))
              .withValues(alpha: 0.62),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.blur_circular_rounded,
              color: palette.textMuted,
              size: 22,
            ),
            const SizedBox(height: 7),
            Text(
              context.l10n.commonMore,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: palette.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

const List<String> collectionIconCatalogKeys = <String>[
  'folder',
  'star',
  'favorite',
  'travel_explore',
  'camera',
  'work',
  'book',
  'music_note',
  'map',
  'description',
  'payments',
  'home_work',
  'workspaces',
  'home',
  'fitness_center',
  'restaurant',
  'school',
  'pets',
  'directions_car',
  'shopping_bag',
  'flight',
  'medical_services',
  'code',
  'palette',
  'event',
  'verified_user',
  'subscriptions',
  'home_repair_service',
];

String collectionIconLabel(String key) {
  final normalized = key.trim();
  if (normalized.isEmpty) {
    return 'Folder';
  }
  return normalized
      .split('_')
      .where((item) => item.trim().isNotEmpty)
      .map((item) => '${item[0].toUpperCase()}${item.substring(1)}')
      .join(' ');
}

List<String> searchCollectionIconKeys(String query) {
  final normalizedQuery = query.trim().toLowerCase();
  if (normalizedQuery.isEmpty) {
    return collectionIconCatalogKeys;
  }
  return collectionIconCatalogKeys
      .where((key) {
        final normalizedKey = key.toLowerCase();
        final normalizedLabel = collectionIconLabel(key).toLowerCase();
        return normalizedKey.contains(normalizedQuery) ||
            normalizedLabel.contains(normalizedQuery);
      })
      .toList(growable: false);
}

IconData collectionIconFromKey(String key) {
  return switch (key.trim().toLowerCase()) {
    'folder' => Icons.folder_rounded,
    'star' => Icons.star_rounded,
    'favorite' => Icons.favorite_rounded,
    'travel_explore' => Icons.travel_explore_rounded,
    'camera' => Icons.camera_alt_rounded,
    'work' => Icons.work_rounded,
    'book' => Icons.book_rounded,
    'music_note' => Icons.music_note_rounded,
    'map' => Icons.map_rounded,
    'description' => Icons.description_rounded,
    'payments' => Icons.payments_rounded,
    'home_work' => Icons.home_work_rounded,
    'workspaces' => Icons.workspaces_outline,
    'home' => Icons.home_rounded,
    'fitness_center' => Icons.fitness_center_rounded,
    'restaurant' => Icons.restaurant_rounded,
    'school' => Icons.school_rounded,
    'pets' => Icons.pets_rounded,
    'directions_car' => Icons.directions_car_rounded,
    'shopping_bag' => Icons.shopping_bag_rounded,
    'flight' => Icons.flight_rounded,
    'medical_services' => Icons.medical_services_rounded,
    'code' => Icons.code_rounded,
    'palette' => Icons.palette_rounded,
    'event' => Icons.event_rounded,
    'verified_user' => Icons.verified_user_rounded,
    'subscriptions' => Icons.subscriptions_rounded,
    'home_repair_service' => Icons.home_repair_service_rounded,
    _ => Icons.folder_rounded,
  };
}

IconData blockIcon(CollectionBlockType type) {
  return switch (type) {
    CollectionBlockType.folder => Icons.folder_rounded,
    CollectionBlockType.section => Icons.view_agenda_rounded,
    CollectionBlockType.document => Icons.description_rounded,
    CollectionBlockType.note => Icons.notes_rounded,
    CollectionBlockType.input => Icons.input_rounded,
    CollectionBlockType.checklist => Icons.checklist_rounded,
    CollectionBlockType.link => Icons.link_rounded,
    CollectionBlockType.image => Icons.image_rounded,
    CollectionBlockType.expense => Icons.payments_rounded,
    CollectionBlockType.timeline => Icons.timeline_rounded,
    CollectionBlockType.location => Icons.place_rounded,
    CollectionBlockType.reminder => Icons.notifications_rounded,
    CollectionBlockType.progress => Icons.donut_small_rounded,
  };
}

Color blockSoftColor(CollectionBlockType type) {
  return switch (type) {
    CollectionBlockType.folder => const Color(0xFFE9EEFF),
    CollectionBlockType.section => const Color(0xFFE8ECF4),
    CollectionBlockType.document => const Color(0xFFF9EEDC),
    CollectionBlockType.note => const Color(0xFFE8F8F2),
    CollectionBlockType.input => const Color(0xFFF0F3F7),
    CollectionBlockType.checklist => const Color(0xFFF0EDFF),
    CollectionBlockType.link => const Color(0xFFE8F8FD),
    CollectionBlockType.image => const Color(0xFFFDECF3),
    CollectionBlockType.expense => const Color(0xFFE7F9EF),
    CollectionBlockType.timeline => const Color(0xFFFFF1E5),
    CollectionBlockType.location => const Color(0xFFEAF0FF),
    CollectionBlockType.reminder => const Color(0xFFFFF3E0),
    CollectionBlockType.progress => const Color(0xFFE8F0FF),
  };
}

Color blockColor(CollectionBlockType type) {
  return switch (type) {
    CollectionBlockType.folder => const Color(0xFF2A5CD6),
    CollectionBlockType.section => const Color(0xFF5C6F8A),
    CollectionBlockType.document => const Color(0xFFE89A16),
    CollectionBlockType.note => const Color(0xFF19A672),
    CollectionBlockType.input => const Color(0xFF7C8CA6),
    CollectionBlockType.checklist => const Color(0xFF6E56DB),
    CollectionBlockType.link => const Color(0xFF2AAEDC),
    CollectionBlockType.image => const Color(0xFFE55B87),
    CollectionBlockType.expense => const Color(0xFF13A567),
    CollectionBlockType.timeline => const Color(0xFFF08A31),
    CollectionBlockType.location => const Color(0xFF3D79EA),
    CollectionBlockType.reminder => const Color(0xFFE8890C),
    CollectionBlockType.progress => const Color(0xFF3B6DE8),
  };
}

Widget buildCollectionLeadingIcon(
  BuildContext context, {
  required String iconKey,
  required Color accent,
  String? iconEmoji,
  String? iconImagePath,
  double shellSize = 46,
  double shellRadius = 14,
  double iconSize = 21,
}) {
  final imagePath = (iconImagePath ?? '').trim();
  if (imagePath.isNotEmpty) {
    final resolvedPath = LocalAssetPathResolver.resolveRuntimePathSync(
      imagePath,
    );
    final provider = resolveLocalFileImageProvider(resolvedPath);
    if (provider != null) {
      return _containedImageIconShell(
        context,
        provider: provider,
        shellColor: accent.withValues(alpha: 0.16),
        shellSize: shellSize,
        shellRadius: shellRadius,
        fallback: _defaultCollectionIconShell(
          iconKey: iconKey,
          accent: accent,
          shellSize: shellSize,
          shellRadius: shellRadius,
          iconSize: iconSize,
        ),
      );
    }
  }

  final emoji = normalizeCollectionEmoji(iconEmoji);
  if (emoji.isNotEmpty) {
    return Container(
      width: shellSize,
      height: shellSize,
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(shellRadius),
      ),
      alignment: Alignment.center,
      child: Text(emoji, style: TextStyle(fontSize: iconSize + 6)),
    );
  }

  return _defaultCollectionIconShell(
    iconKey: iconKey,
    accent: accent,
    shellSize: shellSize,
    shellRadius: shellRadius,
    iconSize: iconSize,
  );
}

Widget _defaultCollectionIconShell({
  required String iconKey,
  required Color accent,
  required double shellSize,
  required double shellRadius,
  required double iconSize,
}) {
  return Container(
    width: shellSize,
    height: shellSize,
    decoration: BoxDecoration(
      color: accent.withValues(alpha: 0.16),
      borderRadius: BorderRadius.circular(shellRadius),
    ),
    alignment: Alignment.center,
    child: Icon(collectionIconFromKey(iconKey), size: iconSize, color: accent),
  );
}

Widget buildCollectionBlockLeadingIcon(
  BuildContext context, {
  required CollectionBlockType type,
  required Map<String, String> metadata,
  double shellSize = 46,
  double shellRadius = 14,
  double iconSize = 21,
}) {
  final imagePath = (metadata[CollectionBlockMetadataKeys.iconImagePath] ?? '')
      .trim();
  final emoji = normalizeCollectionEmoji(
    metadata[CollectionBlockMetadataKeys.iconEmoji],
  );
  final iconKey = (metadata[CollectionBlockMetadataKeys.iconKey] ?? '').trim();

  if (imagePath.isNotEmpty) {
    final resolvedPath = LocalAssetPathResolver.resolveRuntimePathSync(
      imagePath,
    );
    final provider = resolveLocalFileImageProvider(resolvedPath);
    if (provider != null) {
      return _containedImageIconShell(
        context,
        provider: provider,
        shellColor: blockSoftColor(type),
        shellSize: shellSize,
        shellRadius: shellRadius,
        fallback: _defaultBlockIconShell(
          type: type,
          shellSize: shellSize,
          shellRadius: shellRadius,
          iconSize: iconSize,
        ),
      );
    }
  }

  if (emoji.isNotEmpty) {
    return Container(
      width: shellSize,
      height: shellSize,
      decoration: BoxDecoration(
        color: blockSoftColor(type),
        borderRadius: BorderRadius.circular(shellRadius),
      ),
      alignment: Alignment.center,
      child: Text(emoji, style: TextStyle(fontSize: iconSize + 6)),
    );
  }

  if (iconKey.isNotEmpty) {
    return Container(
      width: shellSize,
      height: shellSize,
      decoration: BoxDecoration(
        color: blockSoftColor(type),
        borderRadius: BorderRadius.circular(shellRadius),
      ),
      alignment: Alignment.center,
      child: Icon(
        collectionIconFromKey(iconKey),
        color: blockColor(type),
        size: iconSize,
      ),
    );
  }

  return _defaultBlockIconShell(
    type: type,
    shellSize: shellSize,
    shellRadius: shellRadius,
    iconSize: iconSize,
  );
}

bool collectionBlockHasCustomIcon(Map<String, String> metadata) {
  final imagePath = (metadata[CollectionBlockMetadataKeys.iconImagePath] ?? '')
      .trim();
  final emoji = normalizeCollectionEmoji(
    metadata[CollectionBlockMetadataKeys.iconEmoji],
  );
  final iconKey = (metadata[CollectionBlockMetadataKeys.iconKey] ?? '').trim();
  return imagePath.isNotEmpty || emoji.isNotEmpty || iconKey.isNotEmpty;
}

Widget _containedImageIconShell(
  BuildContext context, {
  required ImageProvider provider,
  required Color shellColor,
  required double shellSize,
  required double shellRadius,
  required Widget fallback,
}) {
  final palette = context.appPalette;
  final innerPadding = math.max(4.0, shellSize * 0.1);
  final innerRadius = math.max(8.0, shellRadius - 4);

  return Container(
    width: shellSize,
    height: shellSize,
    decoration: BoxDecoration(
      color: shellColor,
      borderRadius: BorderRadius.circular(shellRadius),
    ),
    padding: EdgeInsets.all(innerPadding),
    child: Container(
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(innerRadius),
      ),
      clipBehavior: Clip.antiAlias,
      child: Image(
        image: provider,
        fit: BoxFit.contain,
        alignment: Alignment.center,
        filterQuality: FilterQuality.high,
        errorBuilder: (_, __, ___) => fallback,
      ),
    ),
  );
}

Widget _defaultBlockIconShell({
  required CollectionBlockType type,
  required double shellSize,
  required double shellRadius,
  required double iconSize,
}) {
  return Container(
    width: shellSize,
    height: shellSize,
    decoration: BoxDecoration(
      color: blockSoftColor(type),
      borderRadius: BorderRadius.circular(shellRadius),
    ),
    alignment: Alignment.center,
    child: Icon(blockIcon(type), color: blockColor(type), size: iconSize),
  );
}

class _DashedRoundedBorderPainter extends CustomPainter {
  const _DashedRoundedBorderPainter({
    required this.color,
    required this.strokeWidth,
    required this.radius,
    required this.dashLength,
    required this.gapLength,
  });

  final Color color;
  final double strokeWidth;
  final double radius;
  final double dashLength;
  final double gapLength;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(radius),
    );
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    final path = Path()..addRRect(rect);
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final next = math.min(distance + dashLength, metric.length);
        canvas.drawPath(metric.extractPath(distance, next), paint);
        distance += dashLength + gapLength;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedRoundedBorderPainter oldDelegate) {
    return color != oldDelegate.color ||
        strokeWidth != oldDelegate.strokeWidth ||
        radius != oldDelegate.radius ||
        dashLength != oldDelegate.dashLength ||
        gapLength != oldDelegate.gapLength;
  }
}
