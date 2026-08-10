import 'package:flutter/material.dart';
import 'package:pass_doc_manager/app/theme/app_palette.dart';
import 'package:pass_doc_manager/domain/bundles/entities/bundle_event.dart';
import 'package:pass_doc_manager/features/bundles/presentation/support/bundle_relative_time.dart';
import 'package:pass_doc_manager/l10n/app_localizations.dart';
import 'package:pass_doc_manager/l10n/l10n.dart';

class BundleHistoryTimeline extends StatelessWidget {
  const BundleHistoryTimeline({super.key, required this.events});

  final List<BundleEvent> events;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    final l10n = context.l10n;
    if (events.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 22),
        decoration: BoxDecoration(
          color: palette.surfaceSoft,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: palette.primarySoft,
                borderRadius: BorderRadius.circular(14),
              ),
              alignment: Alignment.center,
              child: Icon(
                Icons.timeline_rounded,
                color: palette.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                l10n.bundleHistoryEmpty,
                style: TextStyle(color: palette.textSecondary, fontSize: 13),
              ),
            ),
          ],
        ),
      );
    }
    final reversed = events.reversed.toList(growable: false);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < reversed.length; i++) ...[
          _HistoryRow(
            event: reversed[i],
            palette: palette,
            l10n: l10n,
            isLatest: i == 0,
            hasConnector: i < reversed.length - 1,
          ),
          if (i < reversed.length - 1) const SizedBox(height: 12),
        ],
      ],
    );
  }
}

class _HistoryRow extends StatelessWidget {
  const _HistoryRow({
    required this.event,
    required this.palette,
    required this.l10n,
    required this.isLatest,
    required this.hasConnector,
  });

  final BundleEvent event;
  final AppPalette palette;
  final AppLocalizations l10n;
  final bool isLatest;
  final bool hasConnector;

  String _labelFor(BundleEventKind kind) {
    switch (kind) {
      case BundleEventKind.created:
        return l10n.bundleEventCreated;
      case BundleEventKind.renamed:
        return l10n.bundleEventRenamed;
      case BundleEventKind.purposeUpdated:
        return l10n.bundleEventPurposeUpdated;
      case BundleEventKind.descriptionUpdated:
        return l10n.bundleEventDescriptionUpdated;
      case BundleEventKind.itemAdded:
        return l10n.bundleEventItemAdded;
      case BundleEventKind.itemRemoved:
        return l10n.bundleEventItemRemoved;
      case BundleEventKind.itemReordered:
        return l10n.bundleEventItemReordered;
      case BundleEventKind.statusChanged:
        return l10n.bundleEventStatusChanged;
      case BundleEventKind.exported:
        return l10n.bundleEventExported;
      case BundleEventKind.archived:
        return l10n.bundleEventArchived;
      case BundleEventKind.restored:
        return l10n.bundleEventRestored;
    }
  }

  IconData _iconFor(BundleEventKind kind) {
    switch (kind) {
      case BundleEventKind.created:
        return Icons.auto_awesome_rounded;
      case BundleEventKind.renamed:
        return Icons.drive_file_rename_outline_rounded;
      case BundleEventKind.purposeUpdated:
      case BundleEventKind.descriptionUpdated:
        return Icons.edit_note_rounded;
      case BundleEventKind.itemAdded:
        return Icons.add_circle_rounded;
      case BundleEventKind.itemRemoved:
        return Icons.remove_circle_rounded;
      case BundleEventKind.itemReordered:
        return Icons.reorder_rounded;
      case BundleEventKind.statusChanged:
        return Icons.flag_circle_rounded;
      case BundleEventKind.exported:
        return Icons.ios_share_rounded;
      case BundleEventKind.archived:
        return Icons.archive_rounded;
      case BundleEventKind.restored:
        return Icons.unarchive_rounded;
    }
  }

  Color _accentFor(BundleEventKind kind) {
    switch (kind) {
      case BundleEventKind.created:
      case BundleEventKind.renamed:
      case BundleEventKind.purposeUpdated:
      case BundleEventKind.descriptionUpdated:
      case BundleEventKind.statusChanged:
        return palette.primary;
      case BundleEventKind.itemAdded:
      case BundleEventKind.restored:
        return palette.success;
      case BundleEventKind.exported:
        return palette.warning;
      case BundleEventKind.archived:
      case BundleEventKind.itemRemoved:
        return palette.textSecondary;
      case BundleEventKind.itemReordered:
        return palette.primaryAccent;
    }
  }

  @override
  Widget build(BuildContext context) {
    final accent = _accentFor(event.kind);
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 40,
            child: Column(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: isLatest ? 0.16 : 0.1),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: accent.withValues(alpha: isLatest ? 0.28 : 0.14),
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Icon(_iconFor(event.kind), size: 16, color: accent),
                ),
                if (hasConnector)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: palette.stroke,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
              decoration: BoxDecoration(
                color: isLatest
                    ? accent.withValues(alpha: 0.08)
                    : palette.surfaceSoft,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isLatest
                      ? accent.withValues(alpha: 0.18)
                      : palette.stroke,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _labelFor(event.kind),
                    style: TextStyle(
                      color: palette.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (event.detail != null && event.detail!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      event.detail!,
                      style: TextStyle(
                        color: palette.textSecondary,
                        fontSize: 12,
                        height: 1.3,
                      ),
                    ),
                  ],
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(
                        Icons.schedule_rounded,
                        size: 14,
                        color: palette.textMuted,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        formatBundleRelative(event.at, l10n),
                        style: TextStyle(
                          color: palette.textMuted,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
