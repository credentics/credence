import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:pass_doc_manager/app/theme/app_palette.dart';
import 'package:pass_doc_manager/domain/tasks/entities/task_entity.dart';
import 'package:pass_doc_manager/domain/tasks/entities/task_list_entity.dart';
import 'package:pass_doc_manager/domain/tasks/entities/task_priority.dart';
import 'package:pass_doc_manager/features/tasks/presentation/cubit/task_lists_cubit.dart';
import 'package:pass_doc_manager/features/tasks/presentation/cubit/task_lists_state.dart';
import 'package:pass_doc_manager/features/tasks/presentation/pages/task_create_list_page.dart';
import 'package:pass_doc_manager/features/tasks/presentation/pages/task_list_detail_page.dart';
import 'package:pass_doc_manager/features/tasks/presentation/widgets/task_row.dart';
import 'package:pass_doc_manager/features/tasks/presentation/widgets/tasks_reference_ui.dart';
import 'package:pass_doc_manager/l10n/l10n.dart';

class TaskListsPage extends StatelessWidget {
  const TaskListsPage({
    super.key,
    this.embeddedDesktop = false,
    this.currentListId,
    this.presentedAsMenu = false,
  });

  final bool embeddedDesktop;
  final String? currentListId;
  final bool presentedAsMenu;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => TaskListsCubit()..load(),
      child: _TaskListsScaffold(
        embeddedDesktop: embeddedDesktop,
        currentListId: currentListId,
        presentedAsMenu: presentedAsMenu,
      ),
    );
  }
}

enum _TasksRootMode { lists, today, upcoming, all, archived }

class _TaskListsScaffold extends StatefulWidget {
  const _TaskListsScaffold({
    required this.embeddedDesktop,
    required this.currentListId,
    required this.presentedAsMenu,
  });

  final bool embeddedDesktop;
  final String? currentListId;
  final bool presentedAsMenu;

  @override
  State<_TaskListsScaffold> createState() => _TaskListsScaffoldState();
}

class _TaskListsScaffoldState extends State<_TaskListsScaffold> {
  late final TextEditingController _searchController;
  String _query = '';
  TaskPriority? _priorityFilter;
  _TasksRootMode _mode = _TasksRootMode.lists;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _openCreate(BuildContext context) async {
    final cubit = context.read<TaskListsCubit>();
    final created = await Navigator.of(context).push<TaskListEntity>(
      MaterialPageRoute(
        builder: (_) => TaskCreateListPage(
          listCubit: cubit,
          embeddedDesktop: widget.embeddedDesktop,
        ),
      ),
    );
    if (!context.mounted || created == null) return;
    if (widget.presentedAsMenu) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => TaskListDetailPage(
            listId: created.id,
            embeddedDesktop: widget.embeddedDesktop,
          ),
        ),
      );
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TaskListDetailPage(
          listId: created.id,
          embeddedDesktop: widget.embeddedDesktop,
        ),
      ),
    );
    if (context.mounted) await context.read<TaskListsCubit>().load();
  }

  Future<void> _openDetail(BuildContext context, TaskListEntity list) async {
    if (widget.presentedAsMenu && widget.currentListId == list.id) {
      Navigator.of(context).maybePop();
      return;
    }
    if (widget.presentedAsMenu) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => TaskListDetailPage(
            listId: list.id,
            embeddedDesktop: widget.embeddedDesktop,
          ),
        ),
      );
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TaskListDetailPage(
          listId: list.id,
          embeddedDesktop: widget.embeddedDesktop,
        ),
      ),
    );
    if (!context.mounted) return;
    await context.read<TaskListsCubit>().load();
  }

  Future<void> _deleteList(BuildContext context, TaskListEntity list) async {
    final confirmed = await _confirmDeleteList(context, list);
    if (!context.mounted || confirmed != true) return;
    await context.read<TaskListsCubit>().delete(list.id);
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('${list.title} deleted')));
  }

  Future<bool?> _confirmDeleteList(BuildContext context, TaskListEntity list) {
    final l10n = context.l10n;
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        final palette = dialogContext.appPalette;
        return AlertDialog(
          backgroundColor: palette.surface,
          title: Text(l10n.tasksDeleteListTitle),
          content: Text(l10n.tasksDeleteListMessage(list.title)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(l10n.commonCancel),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(
                l10n.tasksDeleteListConfirm,
                style: TextStyle(color: palette.danger),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TaskListsCubit, TaskListsState>(
      builder: (context, state) {
        switch (state.status) {
          case TaskListsStatus.initial:
          case TaskListsStatus.loading:
            return TaskReferencePage(
              child: Center(
                child: CircularProgressIndicator(
                  color: context.appPalette.textPrimary,
                ),
              ),
            );
          case TaskListsStatus.error:
            return TaskReferencePage(
              child: _TaskListsError(
                onRetry: () => context.read<TaskListsCubit>().load(),
              ),
            );
          case TaskListsStatus.ready:
            final activeLists = state.lists
                .where((item) => !item.isArchived)
                .toList();
            final archivedLists = state.lists
                .where((item) => item.isArchived)
                .toList();
            final hits = _taskHits(activeLists);
            return TaskReferencePage(
              maxWidth: widget.embeddedDesktop ? 980 : 720,
              child: RefreshIndicator(
                onRefresh: () => context.read<TaskListsCubit>().load(),
                color: context.appPalette.textPrimary,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.only(bottom: 34),
                  children: switch (_mode) {
                    _TasksRootMode.lists => _buildRoot(
                      context,
                      activeLists,
                      archivedLists,
                      hits,
                    ),
                    _TasksRootMode.today => _buildAggregate(
                      context,
                      activeLists,
                      hits,
                      segment: 0,
                    ),
                    _TasksRootMode.upcoming => _buildAggregate(
                      context,
                      activeLists,
                      hits,
                      segment: 1,
                    ),
                    _TasksRootMode.all => _buildAggregate(
                      context,
                      activeLists,
                      hits,
                      segment: 2,
                    ),
                    _TasksRootMode.archived => _buildArchived(
                      context,
                      archivedLists,
                    ),
                  },
                ),
              ),
            );
        }
      },
    );
  }

  List<Widget> _buildRoot(
    BuildContext context,
    List<TaskListEntity> activeLists,
    List<TaskListEntity> archivedLists,
    List<_TaskHit> hits,
  ) {
    final l10n = context.l10n;
    final openCount = hits.where((hit) => !hit.task.isDone).length;
    final todayCount = hits.where((hit) => hit.task.isDueToday).length;
    final upcomingCount = _upcomingHits(hits).length;
    final filteredLists = _filterLists(activeLists);
    final cubit = context.read<TaskListsCubit>();

    return [
      TaskRefHeader(
        title: l10n.tasksTitle,
        meta: '$openCount OPEN · $todayCount TODAY',
        centerTitle: true,
        leading: _rootBackButton(context),
        trailing: TaskRefIconButton(
          icon: Icons.search_rounded,
          onTap: () => _searchController.text.isEmpty
              ? FocusScope.of(context).nextFocus()
              : setState(() {
                  _searchController.clear();
                  _query = '';
                }),
        ),
      ),
      const SizedBox(height: 8),
      TaskRefSearch(
        controller: _searchController,
        onChanged: (value) => setState(() => _query = value),
        hintText: l10n.workFolderHistorySearchTitle,
      ),
      const SizedBox(height: 14),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 22),
        child: Row(
          children: [
            Expanded(
              child: TaskQStatCard(
                label: l10n.tasksSectionToday,
                count: todayCount,
                meta: 'due now',
                kind: TaskQStatKind.today,
                onTap: () => setState(() => _mode = _TasksRootMode.today),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TaskQStatCard(
                label: l10n.tasksSectionUpcoming,
                count: upcomingCount,
                meta: 'scheduled',
                kind: TaskQStatKind.upcoming,
                onTap: () => setState(() => _mode = _TasksRootMode.upcoming),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 16),
      _PriorityFilters(
        hits: hits,
        selected: _priorityFilter,
        onChanged: (value) => setState(() => _priorityFilter = value),
      ),
      const SizedBox(height: 18),
      TaskRefSectionLabel(label: 'Task list · ${filteredLists.length}'),
      const SizedBox(height: 8),
      if (filteredLists.isEmpty)
        _TaskRootEmpty(onCreate: () => _openCreate(context))
      else
        for (final list in filteredLists) ...[
          TaskListRefCard(
            list: list,
            onTap: () => _openDetail(context, list),
            onArchive: () => cubit.setArchived(list, true),
            onDelete: () => _deleteList(context, list),
          ),
          const SizedBox(height: 8),
        ],
      const SizedBox(height: 4),
      _InlineCreateListRow(onTap: () => _openCreate(context)),
      const SizedBox(height: 18),
      TaskRefSectionLabel(label: 'Archive'),
      const SizedBox(height: 8),
      _ArchiveLauncher(
        count: archivedLists.length,
        onTap: () => setState(() => _mode = _TasksRootMode.archived),
      ),
    ];
  }

  Widget? _rootBackButton(BuildContext context) {
    if (widget.embeddedDesktop) return null;
    return TaskRefIconButton(
      icon: Icons.arrow_back_ios_new_rounded,
      tooltip: context.l10n.commonBack,
      onTap: () => Navigator.of(context).maybePop(),
    );
  }

  List<Widget> _buildAggregate(
    BuildContext context,
    List<TaskListEntity> activeLists,
    List<_TaskHit> hits, {
    required int segment,
  }) {
    final l10n = context.l10n;
    final selectedHits = switch (segment) {
      0 => hits.where((hit) => hit.task.isDueToday).toList(),
      1 => _upcomingHits(hits),
      _ => hits.where((hit) => !hit.task.isDone).toList(),
    }..sort(_compareDueThenPriority);
    final overdue = hits.where((hit) => hit.task.isOverdue).toList()
      ..sort(_compareDueThenPriority);
    final title = switch (segment) {
      0 => l10n.tasksSectionToday,
      1 => l10n.tasksSectionUpcoming,
      _ => l10n.tasksTitle,
    };

    return [
      TaskRefHeader(
        title: title,
        meta: '${selectedHits.length} OPEN',
        centerTitle: true,
        leading: TaskRefIconButton(
          icon: Icons.arrow_back_ios_new_rounded,
          onTap: () => setState(() => _mode = _TasksRootMode.lists),
        ),
        trailing: TaskRefIconButton(
          icon: Icons.add_rounded,
          onTap: () => _openCreate(context),
        ),
      ),
      const SizedBox(height: 8),
      TaskSegmentedSwitch(
        items: [l10n.tasksSectionToday, l10n.tasksSectionUpcoming, 'All'],
        activeIndex: segment,
        onChanged: (index) => setState(() {
          _mode = switch (index) {
            0 => _TasksRootMode.today,
            1 => _TasksRootMode.upcoming,
            _ => _TasksRootMode.all,
          };
        }),
      ),
      const SizedBox(height: 14),
      if (segment == 1 && overdue.isNotEmpty) ...[
        TaskOverdueStrip(
          count: overdue.length,
          onReview: () => setState(() => _mode = _TasksRootMode.today),
        ),
        const SizedBox(height: 12),
      ],
      if (selectedHits.isEmpty)
        _AggregateEmpty(
          title: 'Nothing here.',
          subtitle: segment == 0
              ? 'No tasks are due today.'
              : 'No upcoming tasks are scheduled.',
        )
      else
        ..._groupedHitRows(context, selectedHits),
    ];
  }

  List<Widget> _buildArchived(
    BuildContext context,
    List<TaskListEntity> archivedLists,
  ) {
    final cubit = context.read<TaskListsCubit>();
    return [
      TaskRefHeader(
        title: 'Archived',
        meta: '${archivedLists.length} LISTS',
        centerTitle: true,
        leading: TaskRefIconButton(
          icon: Icons.arrow_back_ios_new_rounded,
          onTap: () => setState(() => _mode = _TasksRootMode.lists),
        ),
      ),
      const SizedBox(height: 14),
      if (archivedLists.isEmpty)
        const _AggregateEmpty(
          title: 'No archived lists.',
          subtitle: 'Archived task lists will appear here.',
        )
      else
        for (final list in archivedLists) ...[
          TaskListRefCard(
            list: list,
            archived: true,
            onTap: () => _openDetail(context, list),
            onArchive: () => cubit.setArchived(list, false),
            onDelete: () => _deleteList(context, list),
          ),
          const SizedBox(height: 8),
        ],
    ];
  }

  List<Widget> _groupedHitRows(BuildContext context, List<_TaskHit> hits) {
    final today = <_TaskHit>[];
    final overdue = <_TaskHit>[];
    final upcomingByDay = <DateTime, List<_TaskHit>>{};
    final noDate = <_TaskHit>[];
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);

    for (final hit in hits) {
      final due = hit.task.dueDate;
      if (due == null) {
        noDate.add(hit);
      } else {
        final day = DateTime(due.year, due.month, due.day);
        if (day.isBefore(start)) {
          overdue.add(hit);
        } else if (day == start) {
          today.add(hit);
        } else {
          upcomingByDay.putIfAbsent(day, () => <_TaskHit>[]).add(hit);
        }
      }
    }

    final widgets = <Widget>[];
    void addGroup(String label, List<_TaskHit> group, TaskDayRailKind kind) {
      if (group.isEmpty) return;
      widgets
        ..add(TaskDayRail(label: label, count: group.length, kind: kind))
        ..add(const SizedBox(height: 4))
        ..add(
          _HitCardGroup(
            hits: group,
            onTap: (hit) => _openDetail(context, hit.list),
            onToggle: (hit) =>
                context.read<TaskListsCubit>().toggleTask(hit.task.id),
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

  List<TaskListEntity> _filterLists(List<TaskListEntity> lists) {
    final normalized = _query.trim().toLowerCase();
    return lists
        .where((list) {
          if (_priorityFilter != null &&
              !list.tasks.any(
                (task) => !task.isDone && task.priority == _priorityFilter,
              )) {
            return false;
          }
          if (normalized.isEmpty) return true;
          if (list.title.toLowerCase().contains(normalized)) return true;
          final description = (list.description ?? '').toLowerCase();
          if (description.contains(normalized)) return true;
          return list.tasks.any(
            (task) =>
                task.title.toLowerCase().contains(normalized) ||
                (task.notes ?? '').toLowerCase().contains(normalized) ||
                (task.linkedRef?.displayNameSnapshot ?? '')
                    .toLowerCase()
                    .contains(normalized),
          );
        })
        .toList(growable: false);
  }

  List<_TaskHit> _taskHits(List<TaskListEntity> lists) {
    return [
      for (final list in lists)
        for (final task in list.tasks) _TaskHit(list: list, task: task),
    ];
  }

  List<_TaskHit> _upcomingHits(List<_TaskHit> hits) {
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    return hits
        .where(
          (hit) =>
              !hit.task.isDone &&
              hit.task.dueDate != null &&
              !hit.task.dueDate!.isBefore(tomorrow),
        )
        .toList(growable: false);
  }

  int _compareDueThenPriority(_TaskHit a, _TaskHit b) {
    final dueA = a.task.dueDate;
    final dueB = b.task.dueDate;
    if (dueA != null && dueB != null) {
      final dueCompare = dueA.compareTo(dueB);
      if (dueCompare != 0) return dueCompare;
    } else if (dueA != null) {
      return -1;
    } else if (dueB != null) {
      return 1;
    }
    final priority = b.task.priority.index.compareTo(a.task.priority.index);
    if (priority != 0) return priority;
    return a.task.position.compareTo(b.task.position);
  }
}

class _TaskHit {
  const _TaskHit({required this.list, required this.task});

  final TaskListEntity list;
  final TaskEntity task;
}

class _PriorityFilters extends StatelessWidget {
  const _PriorityFilters({
    required this.hits,
    required this.selected,
    required this.onChanged,
  });

  final List<_TaskHit> hits;
  final TaskPriority? selected;
  final ValueChanged<TaskPriority?> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    int count(TaskPriority? priority) {
      return hits
          .where(
            (hit) =>
                !hit.task.isDone &&
                (priority == null || hit.task.priority == priority),
          )
          .length;
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 22),
      child: Row(
        children: [
          TaskPriorityFilterChip(
            label: 'All',
            priority: null,
            count: count(null),
            active: selected == null,
            onTap: () => onChanged(null),
          ),
          const SizedBox(width: 8),
          TaskPriorityFilterChip(
            label: l10n.taskPriorityLow,
            priority: TaskPriority.low,
            count: count(TaskPriority.low),
            active: selected == TaskPriority.low,
            onTap: () => onChanged(TaskPriority.low),
          ),
          const SizedBox(width: 8),
          TaskPriorityFilterChip(
            label: l10n.taskPriorityMedium,
            priority: TaskPriority.medium,
            count: count(TaskPriority.medium),
            active: selected == TaskPriority.medium,
            onTap: () => onChanged(TaskPriority.medium),
          ),
          const SizedBox(width: 8),
          TaskPriorityFilterChip(
            label: l10n.taskPriorityHigh,
            priority: TaskPriority.high,
            count: count(TaskPriority.high),
            active: selected == TaskPriority.high,
            onTap: () => onChanged(TaskPriority.high),
          ),
        ],
      ),
    );
  }
}

class _HitCardGroup extends StatelessWidget {
  const _HitCardGroup({
    required this.hits,
    required this.onTap,
    required this.onToggle,
  });

  final List<_TaskHit> hits;
  final ValueChanged<_TaskHit> onTap;
  final ValueChanged<_TaskHit> onToggle;

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
            for (var i = 0; i < hits.length; i++) ...[
              TaskRow(
                task: hits[i].task,
                accent: palette.textPrimary,
                subtitle: hits[i].list.title,
                onToggle: () => onToggle(hits[i]),
                onTap: () => onTap(hits[i]),
              ),
              if (i != hits.length - 1)
                Divider(height: 1, color: palette.stroke),
            ],
          ],
        ),
      ),
    );
  }
}

class _InlineCreateListRow extends StatelessWidget {
  const _InlineCreateListRow({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          height: 50,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Row(
            children: [
              Icon(Icons.add_rounded, color: palette.textMuted, size: 23),
              const SizedBox(width: 12),
              Text(
                context.l10n.tasksListCreateAction,
                style: TextStyle(
                  fontFamily: taskFontDisplay,
                  color: palette.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ArchiveLauncher extends StatelessWidget {
  const _ArchiveLauncher({required this.count, required this.onTap});

  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          height: 50,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Row(
            children: [
              Icon(Icons.tune_rounded, color: palette.textMuted, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  context.l10n.tasksShowArchived,
                  style: TextStyle(
                    fontFamily: taskFontDisplay,
                    color: palette.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                '$count',
                style: TextStyle(
                  fontFamily: taskFontMono,
                  color: palette.textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TaskRootEmpty extends StatelessWidget {
  const _TaskRootEmpty({required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 8),
      child: Column(
        children: [
          const TaskEmptyStack(),
          Text(
            context.l10n.tasksEmptyTitle,
            style: TextStyle(
              fontFamily: taskFontDisplay,
              color: palette.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            context.l10n.tasksEmptySubtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: taskFontBody,
              color: palette.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w500,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              TaskStarterChip(label: 'Visa prep', onTap: onCreate),
              TaskStarterChip(label: 'Apartment move', onTap: onCreate),
              TaskStarterChip(label: 'Travel checklist', onTap: onCreate),
            ],
          ),
          const SizedBox(height: 14),
        ],
      ),
    );
  }
}

class _AggregateEmpty extends StatelessWidget {
  const _AggregateEmpty({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 30, 22, 0),
      child: Column(
        children: [
          const TaskEmptyStack(),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: taskFontDisplay,
              color: palette.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: taskFontBody,
              color: palette.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w500,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

class _TaskListsError extends StatelessWidget {
  const _TaskListsError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded, color: palette.danger, size: 34),
            const SizedBox(height: 12),
            Text(
              context.l10n.tasksErrorLoad,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: taskFontBody,
                color: palette.textSecondary,
              ),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: onRetry,
              child: Text(
                MaterialLocalizations.of(context).continueButtonLabel,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
