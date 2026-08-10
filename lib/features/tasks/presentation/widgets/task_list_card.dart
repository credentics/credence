import 'package:flutter/material.dart';
import 'package:pass_doc_manager/app/theme/app_palette.dart';
import 'package:pass_doc_manager/domain/tasks/entities/task_list_entity.dart';
import 'package:pass_doc_manager/features/tasks/presentation/support/task_visuals.dart';
import 'package:pass_doc_manager/l10n/l10n.dart';

class TaskListCard extends StatelessWidget {
  const TaskListCard({
    super.key,
    required this.list,
    required this.onTap,
    this.onArchive,
    this.onDelete,
  });

  final TaskListEntity list;
  final VoidCallback onTap;
  final VoidCallback? onArchive;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    final l10n = context.l10n;
    final accent = TaskVisualOptions.parseAccent(list.accentColorHex);
    final progress = list.progress.clamp(0.0, 1.0).toDouble();
    final percent = (progress * 100).round();

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(28),
        child: Ink(
          padding: const EdgeInsets.fromLTRB(18, 18, 14, 18),
          decoration: BoxDecoration(
            color: palette.surface,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: list.overdueCount > 0
                  ? palette.danger.withValues(alpha: 0.14)
                  : palette.stroke.withValues(alpha: 0.7),
            ),
            boxShadow: [
              BoxShadow(
                color: palette.shadow.withValues(alpha: 0.035),
                blurRadius: 22,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      TaskVisualOptions.iconFor(list.iconKey),
                      size: 24,
                      color: accent,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          list.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: palette.textPrimary,
                            fontSize: 17.5,
                            fontWeight: FontWeight.w800,
                            height: 1.15,
                          ),
                        ),
                        if ((list.description ?? '').trim().isNotEmpty) ...[
                          const SizedBox(height: 5),
                          Text(
                            list.description!,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: palette.textSecondary,
                              fontSize: 13,
                              height: 1.35,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 9,
                        ),
                        decoration: BoxDecoration(
                          color: palette.surfaceSoft,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Text(
                          '$percent%',
                          style: TextStyle(
                            color: palette.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      if (onArchive != null || onDelete != null)
                        PopupMenuButton<String>(
                          tooltip: MaterialLocalizations.of(
                            context,
                          ).showMenuTooltip,
                          icon: Icon(
                            Icons.more_horiz_rounded,
                            color: palette.textMuted,
                          ),
                          onSelected: (value) {
                            switch (value) {
                              case 'archive':
                                onArchive?.call();
                                return;
                              case 'delete':
                                onDelete?.call();
                                return;
                            }
                          },
                          itemBuilder: (context) => [
                            if (onArchive != null)
                              PopupMenuItem<String>(
                                value: 'archive',
                                child: Row(
                                  children: [
                                    Icon(
                                      list.isArchived
                                          ? Icons.unarchive_rounded
                                          : Icons.archive_rounded,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      list.isArchived
                                          ? l10n.tasksActionUnarchive
                                          : l10n.tasksActionArchive,
                                    ),
                                  ],
                                ),
                              ),
                            if (onDelete != null)
                              PopupMenuItem<String>(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.delete_outline_rounded,
                                      size: 18,
                                      color: palette.danger,
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      l10n.tasksActionDelete,
                                      style: TextStyle(color: palette.danger),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _SoftMetricChip(
                    label: l10n.tasksOpenCount(list.openCount),
                    background: accent.withValues(alpha: 0.12),
                    foreground: accent,
                  ),
                  _SoftMetricChip(
                    label: l10n.tasksDoneCount(list.doneCount),
                    background: palette.surfaceSoft,
                    foreground: palette.textSecondary,
                  ),
                  if (list.overdueCount > 0)
                    _SoftMetricChip(
                      label: l10n.tasksOverdueBadge(list.overdueCount),
                      background: palette.dangerSoft,
                      foreground: palette.danger,
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 7,
                        backgroundColor: palette.stroke,
                        valueColor: AlwaysStoppedAnimation<Color>(accent),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Icon(
                    Icons.arrow_forward_rounded,
                    size: 18,
                    color: palette.textMuted,
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

class _SoftMetricChip extends StatelessWidget {
  const _SoftMetricChip({
    required this.label,
    required this.background,
    required this.foreground,
  });

  final String label;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: foreground,
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
