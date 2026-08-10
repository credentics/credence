import 'package:flutter/material.dart';
import 'package:pass_doc_manager/app/theme/app_palette.dart';
import 'package:pass_doc_manager/features/backup/presentation/support/backup_freshness_report.dart';
import 'package:pass_doc_manager/features/settings/presentation/widgets/settings_reference_ui.dart';

enum PendingBackupChangesDecision { skipDeletes, confirmDeletes }

Future<PendingBackupChangesDecision?> showPendingBackupChangesSheet(
  BuildContext context,
  BackupFreshnessReport? report, {
  bool requireDeleteDecision = false,
  String providerLabel = 'cloud',
}) {
  final palette = context.appPalette;
  final items = backupFreshnessAllPendingItems(report);
  final pendingCount = report?.pendingCount ?? items.length;
  final deleteCount = backupFreshnessDeleteCount(report);
  final countLabel = pendingCount > items.length
      ? '${items.length} of $pendingCount'
      : '${items.length}';

  return showModalBottomSheet<PendingBackupChangesDecision>(
    context: context,
    isScrollControlled: true,
    backgroundColor: palette.background,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (sheetContext) {
      return DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.78,
        minChildSize: 0.45,
        maxChildSize: 0.92,
        builder: (context, scrollController) {
          final sheetPalette = context.appPalette;
          return SafeArea(
            top: false,
            child: Column(
              children: [
                const SizedBox(height: 10),
                Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: sheetPalette.strokeStrong,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Review pending changes',
                              style: TextStyle(
                                fontFamily: settingsFontDisplay,
                                color: sheetPalette.textPrimary,
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.25,
                              ),
                            ),
                          ),
                          Text(
                            countLabel,
                            style: TextStyle(
                              fontFamily: settingsFontMono,
                              color: sheetPalette.textMuted,
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        deleteCount > 0
                            ? '$deleteCount deletions are in this change set. Review them before changing $providerLabel.'
                            : items.isEmpty
                            ? 'No pending changes were found.'
                            : 'These are the local changes waiting to be synchronized.',
                        style: TextStyle(
                          fontFamily: settingsFontDisplay,
                          color: sheetPalette.textSecondary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          height: 1.28,
                        ),
                      ),
                      if (deleteCount > 0 && requireDeleteDecision) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: sheetPalette.warning.withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: sheetPalette.warning.withValues(
                                alpha: 0.22,
                              ),
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.warning_amber_rounded,
                                color: sheetPalette.warning,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Use sync without deletions if this list is unexpected. Credence will keep remote files untouched and repair the local baseline.',
                                  style: TextStyle(
                                    fontFamily: settingsFontDisplay,
                                    color: sheetPalette.textPrimary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    height: 1.25,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Expanded(
                  child: items.isEmpty
                      ? Center(
                          child: Text(
                            'Nothing to review',
                            style: TextStyle(
                              fontFamily: settingsFontDisplay,
                              color: sheetPalette.textMuted,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        )
                      : ListView.separated(
                          controller: scrollController,
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                          itemCount: items.length,
                          separatorBuilder: (_, _) =>
                              Divider(height: 1, color: sheetPalette.stroke),
                          itemBuilder: (context, index) {
                            final item = items[index];
                            final isDelete = item.typeLabel == 'Delete';
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 11),
                              child: Row(
                                children: [
                                  Icon(
                                    pendingBackupChangeIcon(item.typeLabel),
                                    color: isDelete
                                        ? sheetPalette.danger
                                        : sheetPalette.textMuted,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.title,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontFamily: settingsFontDisplay,
                                            color: sheetPalette.textPrimary,
                                            fontSize: 13.5,
                                            fontWeight: FontWeight.w700,
                                            height: 1.18,
                                          ),
                                        ),
                                        if (item.detail.trim().isNotEmpty) ...[
                                          const SizedBox(height: 3),
                                          Text(
                                            item.detail,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontFamily: settingsFontDisplay,
                                              color: sheetPalette.textSecondary,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              height: 1.2,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    item.typeLabel,
                                    style: TextStyle(
                                      fontFamily: settingsFontMono,
                                      color: isDelete
                                          ? sheetPalette.danger
                                          : sheetPalette.textMuted,
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 0.45,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 14),
                  child: _PendingChangesSheetActions(
                    deleteCount: deleteCount,
                    requireDeleteDecision: requireDeleteDecision,
                  ),
                ),
              ],
            ),
          );
        },
      );
    },
  );
}

Future<bool> showDiscardLocalChangesConfirmation(
  BuildContext context,
  BackupFreshnessReport? report, {
  String providerLabel = 'cloud',
}) {
  final controller = TextEditingController();
  final items = backupFreshnessAllPendingItems(report);
  final pendingCount = report?.pendingCount ?? items.length;
  final palette = context.appPalette;

  return showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (context, setState) {
          final dialogPalette = context.appPalette;
          final canDiscard = controller.text.trim().toUpperCase() == 'DISCARD';
          return AlertDialog(
            backgroundColor: dialogPalette.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(22),
            ),
            title: Text(
              'Discard local changes?',
              style: TextStyle(
                fontFamily: settingsFontDisplay,
                color: dialogPalette.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.2,
              ),
            ),
            content: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: dialogPalette.danger.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: dialogPalette.danger.withValues(alpha: 0.22),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.warning_amber_rounded,
                          color: dialogPalette.danger,
                          size: 18,
                        ),
                        const SizedBox(width: 9),
                        Expanded(
                          child: Text(
                            'This replaces local vault data with the $providerLabel mirror. The pending local changes below will be lost on this device. The cloud copy is not modified.',
                            style: TextStyle(
                              fontFamily: settingsFontDisplay,
                              color: dialogPalette.textPrimary,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              height: 1.28,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'LOCAL CHANGES TO DISCARD',
                          style: TextStyle(
                            fontFamily: settingsFontMono,
                            color: dialogPalette.textMuted,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.65,
                          ),
                        ),
                      ),
                      Text(
                        '$pendingCount',
                        style: TextStyle(
                          fontFamily: settingsFontMono,
                          color: dialogPalette.textMuted,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 220),
                    child: items.isEmpty
                        ? Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: dialogPalette.surfaceSoft,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Text(
                              'No pending changes were found.',
                              style: TextStyle(
                                fontFamily: settingsFontDisplay,
                                color: dialogPalette.textMuted,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          )
                        : ListView.separated(
                            shrinkWrap: true,
                            itemCount: items.length,
                            separatorBuilder: (_, _) =>
                                Divider(height: 1, color: dialogPalette.stroke),
                            itemBuilder: (context, index) {
                              final item = items[index];
                              final isDelete = item.typeLabel == 'Delete';
                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 9,
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      pendingBackupChangeIcon(item.typeLabel),
                                      color: isDelete
                                          ? dialogPalette.danger
                                          : dialogPalette.textMuted,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 9),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            item.title,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontFamily: settingsFontDisplay,
                                              color: dialogPalette.textPrimary,
                                              fontSize: 13,
                                              fontWeight: FontWeight.w700,
                                              height: 1.18,
                                            ),
                                          ),
                                          if (item.detail
                                              .trim()
                                              .isNotEmpty) ...[
                                            const SizedBox(height: 3),
                                            Text(
                                              item.detail,
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontFamily: settingsFontDisplay,
                                                color:
                                                    dialogPalette.textSecondary,
                                                fontSize: 11.5,
                                                fontWeight: FontWeight.w600,
                                                height: 1.18,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      item.typeLabel,
                                      style: TextStyle(
                                        fontFamily: settingsFontMono,
                                        color: isDelete
                                            ? dialogPalette.danger
                                            : dialogPalette.textMuted,
                                        fontSize: 9,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 0.4,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: controller,
                    onChanged: (_) => setState(() {}),
                    textCapitalization: TextCapitalization.characters,
                    decoration: InputDecoration(
                      labelText: 'Type DISCARD to continue',
                      labelStyle: TextStyle(
                        fontFamily: settingsFontDisplay,
                        color: dialogPalette.textMuted,
                        fontWeight: FontWeight.w700,
                      ),
                      filled: true,
                      fillColor: dialogPalette.surfaceSoft,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 13,
                        vertical: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: dialogPalette.stroke),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: dialogPalette.stroke),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(
                          color: dialogPalette.danger.withValues(alpha: 0.7),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: Text(
                  'Cancel',
                  style: TextStyle(
                    fontFamily: settingsFontDisplay,
                    color: dialogPalette.textSecondary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              ElevatedButton.icon(
                onPressed: canDiscard
                    ? () => Navigator.of(dialogContext).pop(true)
                    : null,
                icon: const Icon(Icons.restore_rounded, size: 17),
                label: const Text('Discard changes'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: dialogPalette.danger,
                  foregroundColor: palette.surface,
                  disabledBackgroundColor: dialogPalette.stroke,
                  disabledForegroundColor: dialogPalette.textMuted,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  textStyle: const TextStyle(
                    fontFamily: settingsFontDisplay,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          );
        },
      );
    },
  ).then((value) {
    controller.dispose();
    return value ?? false;
  });
}

IconData pendingBackupChangeIcon(String typeLabel) {
  return switch (typeLabel) {
    'Add' => Icons.add_circle_outline_rounded,
    'Rename' => Icons.drive_file_rename_outline_rounded,
    'Update' => Icons.sync_rounded,
    'Delete' => Icons.delete_outline_rounded,
    'Remote' => Icons.cloud_download_rounded,
    'Password' => Icons.key_rounded,
    'Document' => Icons.description_rounded,
    'Note' => Icons.sticky_note_2_rounded,
    'Tasks' => Icons.checklist_rounded,
    'Task list' => Icons.checklist_rounded,
    'Collection' => Icons.folder_rounded,
    'Bundle' => Icons.inventory_2_rounded,
    'Vault' => Icons.sync_problem_rounded,
    'Settings' => Icons.tune_rounded,
    _ => Icons.circle_rounded,
  };
}

class _PendingChangesSheetActions extends StatelessWidget {
  const _PendingChangesSheetActions({
    required this.deleteCount,
    required this.requireDeleteDecision,
  });

  final int deleteCount;
  final bool requireDeleteDecision;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    if (!requireDeleteDecision || deleteCount <= 0) {
      return SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton(
          onPressed: () => Navigator.of(context).pop(),
          style: ElevatedButton.styleFrom(
            backgroundColor: palette.textPrimary,
            foregroundColor: palette.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            textStyle: const TextStyle(
              fontFamily: settingsFontDisplay,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
          child: const Text('Done'),
        ),
      );
    }

    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton.icon(
            onPressed: () => Navigator.of(
              context,
            ).pop(PendingBackupChangesDecision.skipDeletes),
            icon: const Icon(Icons.shield_rounded, size: 18),
            label: const Text('Sync without deletions'),
            style: ElevatedButton.styleFrom(
              backgroundColor: palette.textPrimary,
              foregroundColor: palette.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              textStyle: const TextStyle(
                fontFamily: settingsFontDisplay,
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
        const SizedBox(height: 9),
        SizedBox(
          width: double.infinity,
          height: 46,
          child: OutlinedButton.icon(
            onPressed: () => Navigator.of(
              context,
            ).pop(PendingBackupChangesDecision.confirmDeletes),
            icon: const Icon(Icons.delete_outline_rounded, size: 18),
            label: Text(
              deleteCount == 1
                  ? 'Confirm 1 deletion'
                  : 'Confirm $deleteCount deletions',
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: palette.danger,
              side: BorderSide(color: palette.danger.withValues(alpha: 0.35)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              textStyle: const TextStyle(
                fontFamily: settingsFontDisplay,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
