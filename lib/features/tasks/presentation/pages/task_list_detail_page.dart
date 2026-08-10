import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:pass_doc_manager/app/theme/app_palette.dart';
import 'package:pass_doc_manager/domain/tasks/entities/task_entity.dart';
import 'package:pass_doc_manager/domain/tasks/entities/task_list_entity.dart';
import 'package:pass_doc_manager/domain/tasks/entities/task_priority.dart';
import 'package:pass_doc_manager/features/tasks/presentation/cubit/task_list_detail_cubit.dart';
import 'package:pass_doc_manager/features/tasks/presentation/cubit/task_list_detail_state.dart';
import 'package:pass_doc_manager/features/tasks/presentation/pages/task_lists_page.dart';
import 'package:pass_doc_manager/features/tasks/presentation/support/task_visuals.dart';
import 'package:pass_doc_manager/features/tasks/presentation/widgets/task_edit_sheet.dart';
import 'package:pass_doc_manager/features/tasks/presentation/widgets/task_row.dart';
import 'package:pass_doc_manager/features/tasks/presentation/widgets/tasks_reference_ui.dart';
import 'package:pass_doc_manager/l10n/l10n.dart';

class TaskListDetailPage extends StatelessWidget {
  const TaskListDetailPage({
    super.key,
    required this.listId,
    this.embeddedDesktop = false,
  });

  final String listId;
  final bool embeddedDesktop;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => TaskListDetailCubit(listId: listId)..load(),
      child: _TaskListDetailScaffold(embeddedDesktop: embeddedDesktop),
    );
  }
}

class _TaskListDetailScaffold extends StatelessWidget {
  const _TaskListDetailScaffold({required this.embeddedDesktop});

  final bool embeddedDesktop;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    return BlocBuilder<TaskListDetailCubit, TaskListDetailState>(
      builder: (context, state) {
        switch (state.status) {
          case TaskListDetailStatus.initial:
          case TaskListDetailStatus.loading:
            return TaskReferencePage(
              child: Center(
                child: CircularProgressIndicator(color: palette.textPrimary),
              ),
            );
          case TaskListDetailStatus.error:
            return TaskReferencePage(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    context.l10n.tasksListErrorLoad,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: taskFontBody,
                      color: palette.textSecondary,
                    ),
                  ),
                ),
              ),
            );
          case TaskListDetailStatus.ready:
            final list = state.list;
            if (list == null) {
              return const TaskReferencePage(child: SizedBox.shrink());
            }
            return _TaskListDetailView(
              list: list,
              showDone: state.showDone,
              reorderMode: state.reorderMode,
              embeddedDesktop: embeddedDesktop,
            );
        }
      },
    );
  }
}

class _TaskListDetailView extends StatelessWidget {
  const _TaskListDetailView({
    required this.list,
    required this.showDone,
    required this.reorderMode,
    required this.embeddedDesktop,
  });

  final TaskListEntity list;
  final bool showDone;
  final bool reorderMode;
  final bool embeddedDesktop;

  Future<bool> _quickAddTask(BuildContext context, String title) async {
    final normalized = title.trim();
    if (normalized.isEmpty) return false;
    final created = await context.read<TaskListDetailCubit>().addTask(
      title: normalized,
      priority: TaskPriority.low,
    );
    return created != null;
  }

  Future<bool> _addTask(
    BuildContext context, {
    String initialTitle = '',
  }) async {
    final cubit = context.read<TaskListDetailCubit>();
    final result = await showTaskEditSheet(
      context,
      listTitle: list.title,
      initialTitle: initialTitle,
    );
    if (result == null || result.deleteRequested) return false;
    final created = await cubit.addTask(
      title: result.title,
      notes: result.notes,
      dueDate: result.dueDate,
      priority: result.priority,
      linkedRef: result.linkedRef,
      isPinned: result.isPinned,
    );
    return created != null;
  }

  Future<void> _editTask(BuildContext context, TaskEntity task) async {
    final cubit = context.read<TaskListDetailCubit>();
    final result = await showTaskEditSheet(
      context,
      initial: task,
      listTitle: list.title,
    );
    if (result == null) return;
    if (result.deleteRequested) {
      await cubit.remove(task.id);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 5),
          content: Text('${task.title} deleted'),
          action: SnackBarAction(
            label: 'Undo',
            onPressed: () async {
              final restored = await cubit.addTask(
                title: task.title,
                notes: task.notes,
                dueDate: task.dueDate,
                priority: task.priority,
                linkedRef: task.linkedRef,
                isPinned: task.isPinned,
              );
              if (restored != null && task.isDone) {
                await cubit.toggle(restored.id);
              }
            },
          ),
        ),
      );
      return;
    }
    await cubit.updateTask(
      task.copyWith(
        title: result.title,
        notes: result.notes,
        clearNotes: result.notes == null,
        dueDate: result.dueDate,
        clearDueDate: result.dueDate == null,
        priority: result.priority,
        linkedRef: result.linkedRef,
        clearLinkedRef: result.linkedRef == null,
        isPinned: result.isPinned,
      ),
    );
  }

  Future<void> _deleteTask(BuildContext context, TaskEntity task) async {
    final cubit = context.read<TaskListDetailCubit>();
    await cubit.remove(task.id);
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('${task.title} deleted')));
  }

  Future<bool> _confirmDeleteTask(BuildContext context, TaskEntity task) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        final palette = dialogContext.appPalette;
        return AlertDialog(
          backgroundColor: palette.surface,
          title: const Text('Delete task?'),
          content: Text('"${task.title}" will be permanently deleted.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(dialogContext.l10n.commonCancel),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(
                dialogContext.l10n.commonDelete,
                style: TextStyle(color: palette.danger),
              ),
            ),
          ],
        );
      },
    );
    return result == true;
  }

  Future<bool> _confirmClearCompleted(BuildContext context, int count) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        final palette = dialogContext.appPalette;
        return AlertDialog(
          backgroundColor: palette.surface,
          title: const Text('Clear completed tasks?'),
          content: Text(
            '$count completed task${count == 1 ? '' : 's'} will be permanently deleted.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(dialogContext.l10n.commonCancel),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(
                dialogContext.l10n.commonDelete,
                style: TextStyle(color: palette.danger),
              ),
            ),
          ],
        );
      },
    );
    return result == true;
  }

  Future<void> _handleBack(BuildContext context) async {
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      await navigator.maybePop();
      return;
    }
    await navigator.pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => TaskListsPage(embeddedDesktop: embeddedDesktop),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<TaskListDetailCubit>();
    final openTasks = _orderedOpenTasks(list.tasks);
    final completedTasks = list.tasks.where((task) => task.isDone).toList()
      ..sort((a, b) {
        final completedA = a.completedAt ?? a.updatedAt;
        final completedB = b.completedAt ?? b.updatedAt;
        return completedB.compareTo(completedA);
      });

    if (reorderMode) {
      return _ReorderTasksScreen(
        list: list,
        openTasks: openTasks,
        completedTasks: completedTasks,
        onDone: cubit.toggleReorderMode,
      );
    }

    return TaskReferencePage(
      maxWidth: embeddedDesktop ? 980 : 720,
      child: RefreshIndicator(
        color: context.appPalette.textPrimary,
        onRefresh: cubit.refresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 36),
          children: [
            TaskRefHeader(
              title: list.title,
              meta: '${list.doneCount} OF ${list.totalCount} DONE',
              centerTitle: true,
              leading: embeddedDesktop
                  ? null
                  : TaskRefIconButton(
                      icon: Icons.arrow_back_ios_new_rounded,
                      onTap: () => _handleBack(context),
                    ),
              trailing: TaskRefIconButton(
                icon: Icons.tune_rounded,
                onTap: openTasks.length >= 2 ? cubit.toggleReorderMode : null,
              ),
            ),
            const SizedBox(height: 12),
            TaskQuickAddField(
              hintText: context.l10n.taskCreateAction,
              onSubmit: (title) => _quickAddTask(context, title),
              onOpenDetails: (title) => _addTask(context, initialTitle: title),
            ),
            const SizedBox(height: 18),
            if (openTasks.isEmpty && completedTasks.isEmpty)
              _EmptyListBody(
                onStarter: (title) => _quickAddTask(context, title),
              )
            else ...[
              ..._openTaskGroups(context, openTasks),
              if (completedTasks.isNotEmpty) ...[
                const SizedBox(height: 8),
                TaskCompletedHeader(
                  count: completedTasks.length,
                  expanded: showDone,
                  onTap: cubit.toggleShowDone,
                ),
                if (showDone) ...[
                  const SizedBox(height: 6),
                  _TaskCardGroup(
                    tasks: completedTasks,
                    accent: TaskVisualOptions.parseAccent(list.accentColorHex),
                    onToggle: (task) => cubit.toggle(task.id),
                    onTap: (task) => _editTask(context, task),
                    onConfirmDelete: (task) =>
                        _confirmDeleteTask(context, task),
                    onDelete: (task) => _deleteTask(context, task),
                  ),
                  const SizedBox(height: 12),
                  _CompletedActions(
                    onRestoreAll: () async {
                      for (final task in completedTasks) {
                        await cubit.updateTask(
                          task.copyWith(isDone: false, clearCompletedAt: true),
                        );
                      }
                    },
                    onClear: () async {
                      final confirmed = await _confirmClearCompleted(
                        context,
                        completedTasks.length,
                      );
                      if (!confirmed || !context.mounted) return;
                      for (final task in completedTasks) {
                        await cubit.remove(task.id);
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  const TaskRefSectionLabel(
                    label: 'Completed tasks stay searchable',
                  ),
                ],
              ],
            ],
          ],
        ),
      ),
    );
  }

  List<Widget> _openTaskGroups(BuildContext context, List<TaskEntity> tasks) {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final overdue = <TaskEntity>[];
    final today = <TaskEntity>[];
    final upcomingByDay = <DateTime, List<TaskEntity>>{};
    final noDate = <TaskEntity>[];
    for (final task in tasks) {
      final due = task.dueDate;
      if (due == null) {
        noDate.add(task);
      } else {
        final day = DateTime(due.year, due.month, due.day);
        if (day.isBefore(todayStart)) {
          overdue.add(task);
        } else if (day == todayStart) {
          today.add(task);
        } else {
          upcomingByDay.putIfAbsent(day, () => <TaskEntity>[]).add(task);
        }
      }
    }

    final widgets = <Widget>[];
    void addGroup(String label, List<TaskEntity> group, TaskDayRailKind kind) {
      if (group.isEmpty) return;
      widgets
        ..add(TaskDayRail(label: label, count: group.length, kind: kind))
        ..add(const SizedBox(height: 4))
        ..add(
          _TaskCardGroup(
            tasks: group,
            accent: TaskVisualOptions.parseAccent(list.accentColorHex),
            onToggle: (task) =>
                context.read<TaskListDetailCubit>().toggle(task.id),
            onTap: (task) => _editTask(context, task),
            onConfirmDelete: (task) => _confirmDeleteTask(context, task),
            onDelete: (task) => _deleteTask(context, task),
          ),
        )
        ..add(const SizedBox(height: 12));
    }

    addGroup(
      context.l10n.tasksSectionOverdue,
      overdue,
      TaskDayRailKind.overdue,
    );
    addGroup(context.l10n.tasksSectionToday, today, TaskDayRailKind.today);
    final days = upcomingByDay.keys.toList()..sort();
    for (final day in days) {
      final label = DateFormat.MMMEd(
        Localizations.localeOf(context).toLanguageTag(),
      ).format(day);
      addGroup(label, upcomingByDay[day]!, TaskDayRailKind.normal);
    }
    addGroup(context.l10n.tasksSectionNoDate, noDate, TaskDayRailKind.normal);
    return widgets;
  }

  List<TaskEntity> _orderedOpenTasks(List<TaskEntity> tasks) {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final overdue = <TaskEntity>[];
    final today = <TaskEntity>[];
    final upcoming = <TaskEntity>[];
    final undated = <TaskEntity>[];

    for (final task in tasks) {
      if (task.isDone) continue;
      final due = task.dueDate;
      if (due == null) {
        undated.add(task);
      } else if (due.isBefore(todayStart)) {
        overdue.add(task);
      } else if (due.isBefore(todayStart.add(const Duration(days: 1)))) {
        today.add(task);
      } else {
        upcoming.add(task);
      }
    }

    void sortTasks(List<TaskEntity> items, {bool sortByDue = false}) {
      items.sort((a, b) {
        if (a.isPinned != b.isPinned) return a.isPinned ? -1 : 1;
        if (sortByDue) {
          final dueA = a.dueDate;
          final dueB = b.dueDate;
          if (dueA != null && dueB != null) {
            final dueCompare = dueA.compareTo(dueB);
            if (dueCompare != 0) return dueCompare;
          }
        }
        final priorityCompare = b.priority.index.compareTo(a.priority.index);
        if (priorityCompare != 0) return priorityCompare;
        return a.position.compareTo(b.position);
      });
    }

    sortTasks(overdue, sortByDue: true);
    sortTasks(today);
    sortTasks(upcoming, sortByDue: true);
    sortTasks(undated);
    return <TaskEntity>[...overdue, ...today, ...upcoming, ...undated];
  }
}

class _TaskCardGroup extends StatelessWidget {
  const _TaskCardGroup({
    required this.tasks,
    required this.accent,
    required this.onToggle,
    required this.onTap,
    this.onConfirmDelete,
    this.onDelete,
  });

  final List<TaskEntity> tasks;
  final Color accent;
  final ValueChanged<TaskEntity> onToggle;
  final ValueChanged<TaskEntity> onTap;
  final Future<bool> Function(TaskEntity task)? onConfirmDelete;
  final ValueChanged<TaskEntity>? onDelete;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 22),
      child: Container(
        decoration: BoxDecoration(
          color: palette.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: palette.stroke),
        ),
        child: Column(
          children: [
            for (var index = 0; index < tasks.length; index++) ...[
              _SwipeToDeleteTaskRow(
                task: tasks[index],
                accent: accent,
                onToggle: () => onToggle(tasks[index]),
                onTap: () => onTap(tasks[index]),
                onConfirmDelete: onConfirmDelete,
                onDelete: onDelete,
              ),
              if (index != tasks.length - 1)
                Divider(height: 1, color: palette.stroke),
            ],
          ],
        ),
      ),
    );
  }
}

class _SwipeToDeleteTaskRow extends StatelessWidget {
  const _SwipeToDeleteTaskRow({
    required this.task,
    required this.accent,
    required this.onToggle,
    required this.onTap,
    required this.onConfirmDelete,
    required this.onDelete,
  });

  final TaskEntity task;
  final Color accent;
  final VoidCallback onToggle;
  final VoidCallback onTap;
  final Future<bool> Function(TaskEntity task)? onConfirmDelete;
  final ValueChanged<TaskEntity>? onDelete;

  @override
  Widget build(BuildContext context) {
    final row = TaskRow(
      task: task,
      accent: accent,
      onToggle: onToggle,
      onTap: onTap,
    );
    final delete = onDelete;
    if (delete == null) {
      return row;
    }
    return Dismissible(
      key: ValueKey('task_delete_${task.id}'),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        final confirm = onConfirmDelete;
        if (confirm == null) return true;
        return confirm(task);
      },
      onDismissed: (_) => delete(task),
      background: _TaskDeleteSwipeBackground(),
      child: row,
    );
  }
}

class _TaskDeleteSwipeBackground extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    return Container(
      color: palette.dangerSoft.withValues(alpha: 0.75),
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            context.l10n.commonDelete,
            style: TextStyle(
              fontFamily: taskFontBody,
              color: palette.danger,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(width: 8),
          Icon(Icons.delete_outline_rounded, color: palette.danger, size: 22),
        ],
      ),
    );
  }
}

class _CompletedActions extends StatelessWidget {
  const _CompletedActions({required this.onRestoreAll, required this.onClear});

  final VoidCallback onRestoreAll;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 22),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: onRestoreAll,
              style: OutlinedButton.styleFrom(
                foregroundColor: palette.textPrimary,
                side: BorderSide(color: palette.stroke),
                minimumSize: const Size.fromHeight(46),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                textStyle: const TextStyle(
                  fontFamily: taskFontBody,
                  fontWeight: FontWeight.w800,
                ),
              ),
              child: const Text('Restore all'),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: OutlinedButton(
              onPressed: onClear,
              style: OutlinedButton.styleFrom(
                foregroundColor: palette.danger,
                side: BorderSide(color: palette.dangerStroke),
                minimumSize: const Size.fromHeight(46),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                textStyle: const TextStyle(
                  fontFamily: taskFontBody,
                  fontWeight: FontWeight.w800,
                ),
              ),
              child: const Text('Clear completed'),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyListBody extends StatelessWidget {
  const _EmptyListBody({required this.onStarter});

  final ValueChanged<String> onStarter;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 20, 22, 0),
      child: Column(
        children: [
          const TaskEmptyStack(),
          Text(
            'No tasks yet.',
            style: TextStyle(
              fontFamily: taskFontDisplay,
              color: palette.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Capture a quick title now. Add priority, due date, link, and notes later.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: taskFontBody,
              color: palette.textSecondary,
              fontSize: 13,
              height: 1.35,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              TaskStarterChip(
                label: 'Renew passport',
                onTap: () => onStarter('Renew passport'),
              ),
              TaskStarterChip(
                label: 'Book appointment',
                onTap: () => onStarter('Book appointment'),
              ),
              TaskStarterChip(
                label: 'Upload receipt',
                onTap: () => onStarter('Upload receipt'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ReorderTasksScreen extends StatefulWidget {
  const _ReorderTasksScreen({
    required this.list,
    required this.openTasks,
    required this.completedTasks,
    required this.onDone,
  });

  final TaskListEntity list;
  final List<TaskEntity> openTasks;
  final List<TaskEntity> completedTasks;
  final VoidCallback onDone;

  @override
  State<_ReorderTasksScreen> createState() => _ReorderTasksScreenState();
}

class _ReorderTasksScreenState extends State<_ReorderTasksScreen> {
  late List<TaskEntity> _openTasks;

  @override
  void initState() {
    super.initState();
    _openTasks = _sortForReorder(widget.openTasks);
  }

  @override
  void didUpdateWidget(covariant _ReorderTasksScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.openTasks.length != widget.openTasks.length ||
        oldWidget.list.id != widget.list.id) {
      _openTasks = _sortForReorder(widget.openTasks);
    }
  }

  List<TaskEntity> _sortForReorder(List<TaskEntity> tasks) {
    return tasks.toList(growable: true)..sort((a, b) {
      if (a.isPinned != b.isPinned) return a.isPinned ? -1 : 1;
      return a.position.compareTo(b.position);
    });
  }

  void _onReorderItem(int oldIndex, int newIndex) {
    setState(() {
      final moved = _openTasks.removeAt(oldIndex);
      _openTasks.insert(newIndex, moved);
    });
    context.read<TaskListDetailCubit>().reorder(
      _openTasks.map((task) => task.id).toList(growable: false),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    return TaskReferencePage(
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 36),
        children: [
          TaskRefHeader(
            title: context.l10n.tasksEnterReorder,
            meta: widget.list.title,
            centerTitle: true,
            leading: TaskRefIconButton(
              icon: Icons.arrow_back_ios_new_rounded,
              onTap: widget.onDone,
            ),
            trailing: TextButton(
              onPressed: widget.onDone,
              child: Text(
                'Done',
                style: TextStyle(
                  fontFamily: taskFontBody,
                  color: palette.textPrimary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22),
            child: ReorderableListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              buildDefaultDragHandles: false,
              itemCount: _openTasks.length,
              onReorderItem: _onReorderItem,
              proxyDecorator: (child, index, animation) => Material(
                color: Colors.transparent,
                child: ScaleTransition(
                  scale: Tween<double>(begin: 1, end: 1.015).animate(animation),
                  child: child,
                ),
              ),
              itemBuilder: (context, index) {
                final task = _openTasks[index];
                return Padding(
                  key: ValueKey('reorder_${task.id}'),
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _ReorderRow(task: task, index: index),
                );
              },
            ),
          ),
          if (widget.completedTasks.isNotEmpty) ...[
            const SizedBox(height: 10),
            TaskCompletedHeader(
              count: widget.completedTasks.length,
              expanded: true,
              onTap: () {},
            ),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22),
              child: Column(
                children: [
                  for (final task in widget.completedTasks) ...[
                    _LockedReorderRow(task: task),
                    const SizedBox(height: 8),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 8),
            const TaskRefSectionLabel(
              label: 'Uncheck a completed task to reorder it',
            ),
          ],
        ],
      ),
    );
  }
}

class _ReorderRow extends StatelessWidget {
  const _ReorderRow({required this.task, required this.index});

  final TaskEntity task;
  final int index;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 11, 14, 11),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: palette.stroke),
      ),
      child: Row(
        children: [
          ReorderableDragStartListener(index: index, child: const _DragDots()),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              task.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: taskFontDisplay,
                color: palette.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LockedReorderRow extends StatelessWidget {
  const _LockedReorderRow({required this.task});

  final TaskEntity task;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 11, 14, 11),
      decoration: BoxDecoration(
        color: palette.surfaceSoft.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: palette.stroke),
      ),
      child: Row(
        children: [
          Opacity(opacity: 0.35, child: const _DragDots()),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              task.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: taskFontDisplay,
                color: palette.textMuted,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                decoration: TextDecoration.lineThrough,
              ),
            ),
          ),
          Text(
            'LOCKED',
            style: TextStyle(
              fontFamily: taskFontMono,
              color: palette.textMuted,
              fontSize: 9,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
            ),
          ),
        ],
      ),
    );
  }
}

class _DragDots extends StatelessWidget {
  const _DragDots();

  @override
  Widget build(BuildContext context) {
    final color = context.appPalette.textMuted.withValues(alpha: 0.75);
    return SizedBox(
      width: 18,
      height: 24,
      child: Wrap(
        spacing: 3,
        runSpacing: 3,
        children: [
          for (var i = 0; i < 6; i++)
            Container(
              width: 4,
              height: 4,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
        ],
      ),
    );
  }
}
