import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pass_doc_manager/app/theme/app_palette.dart';
import 'package:pass_doc_manager/domain/tasks/entities/task_entity.dart';
import 'package:pass_doc_manager/domain/tasks/entities/task_priority.dart';
import 'package:pass_doc_manager/features/tasks/presentation/widgets/tasks_reference_ui.dart';
import 'package:pass_doc_manager/l10n/l10n.dart';

class TaskRow extends StatelessWidget {
  const TaskRow({
    super.key,
    required this.task,
    required this.accent,
    required this.onToggle,
    required this.onTap,
    this.onEditDetails,
    this.onOpenLinkedRef,
    this.showDueChip = true,
    this.subtitle,
  });

  final TaskEntity task;
  final Color accent;
  final VoidCallback onToggle;
  final VoidCallback onTap;
  final VoidCallback? onEditDetails;
  final VoidCallback? onOpenLinkedRef;
  final bool showDueChip;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    final hasMeta =
        (showDueChip && task.dueDate != null) ||
        task.linkedRef != null ||
        task.isPinned ||
        task.priority != TaskPriority.low ||
        (subtitle ?? '').trim().isNotEmpty;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              TaskCheckbox(
                checked: task.isDone,
                overdue: task.isOverdue,
                onTap: onToggle,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: taskFontDisplay,
                        color: task.isDone
                            ? palette.textMuted
                            : palette.textPrimary,
                        fontSize: 14,
                        fontWeight: task.isDone
                            ? FontWeight.w500
                            : FontWeight.w700,
                        height: 1.25,
                        decoration: task.isDone
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                    if (hasMeta) ...[
                      const SizedBox(height: 4),
                      TaskMetaText(children: _metaSpans(context)),
                    ],
                    if ((task.notes ?? '').trim().isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        task.notes!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: taskFontBody,
                          color: palette.textSecondary,
                          fontSize: 11.5,
                          height: 1.35,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 10),
              const TaskChevron(),
            ],
          ),
        ),
      ),
    );
  }

  List<InlineSpan> _metaSpans(BuildContext context) {
    final spans = <InlineSpan>[];

    void addSep() {
      if (spans.isNotEmpty) {
        spans.add(const TextSpan(text: '  ·  '));
      }
    }

    if (subtitle != null && subtitle!.trim().isNotEmpty) {
      addSep();
      spans.add(TextSpan(text: subtitle!.trim().toUpperCase()));
    }

    if (task.priority != TaskPriority.low) {
      addSep();
      spans.add(
        WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: Padding(
            padding: const EdgeInsets.only(right: 5),
            child: TaskPriorityDot(priority: task.priority),
          ),
        ),
      );
      spans.add(
        TextSpan(text: _priorityLabel(context, task.priority).toUpperCase()),
      );
    }

    if (showDueChip && task.dueDate != null) {
      addSep();
      spans.add(
        TextSpan(text: _formatDate(context, task.dueDate!).toUpperCase()),
      );
    }

    if (task.linkedRef != null) {
      addSep();
      spans.add(
        TextSpan(text: task.linkedRef!.displayNameSnapshot.toUpperCase()),
      );
    }

    if (task.isPinned) {
      addSep();
      spans.add(TextSpan(text: context.l10n.tasksActionPin.toUpperCase()));
    }

    return spans;
  }

  String _priorityLabel(BuildContext context, TaskPriority priority) {
    final l10n = context.l10n;
    switch (priority) {
      case TaskPriority.low:
        return l10n.taskPriorityLow;
      case TaskPriority.medium:
        return l10n.taskPriorityMedium;
      case TaskPriority.high:
        return l10n.taskPriorityHigh;
    }
  }

  String _formatDate(BuildContext context, DateTime date) {
    final locale = Localizations.localeOf(context).toLanguageTag();
    return DateFormat.MMMd(locale).format(date.toLocal());
  }
}
