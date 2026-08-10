import 'package:flutter/foundation.dart';
import 'package:pass_doc_manager/domain/tasks/entities/task_entity.dart';
import 'package:pass_doc_manager/domain/tasks/entities/task_list_entity.dart';
import 'package:pass_doc_manager/domain/tasks/repositories/task_repository.dart';
import 'package:pass_doc_manager/features/collections/presentation/services/reminder_notification_service.dart';
import 'package:pass_doc_manager/features/settings/data/notification_settings_store.dart';

class TaskNotificationService {
  const TaskNotificationService({required TaskRepository taskRepository})
    : _taskRepository = taskRepository;

  final TaskRepository _taskRepository;

  Future<void> scheduleTaskNotifications() async {
    try {
      final prefs = await NotificationSettingsStore.instance.read();
      final lists = await _taskRepository.getTaskLists();
      final candidates = _taskCandidates(lists);
      final now = DateTime.now();
      final notificationService = ReminderNotificationService.instance;

      await _scheduleDueTodayDigest(
        notificationService: notificationService,
        candidates: candidates,
        prefs: prefs,
        now: now,
      );
      await _scheduleOverdueAlerts(
        notificationService: notificationService,
        candidates: candidates,
        prefs: prefs,
        now: now,
      );
    } catch (error) {
      debugPrint('[TaskNotificationService] Failed to schedule tasks: $error');
    }
  }

  Future<void> _scheduleDueTodayDigest({
    required ReminderNotificationService notificationService,
    required List<_TaskNotificationCandidate> candidates,
    required NotificationSettingsPrefs prefs,
    required DateTime now,
  }) async {
    final nextDigestAt = _nextDigestAt(now);
    final digestId = _digestId(nextDigestAt);

    await notificationService.cancelReminder(_digestId(now));
    await notificationService.cancelReminder(digestId);

    if (!prefs.dueTodayDigestEnabled) return;

    final dueOnDigestDay = candidates
        .where(
          (candidate) =>
              !candidate.isListArchived &&
              !candidate.task.isDone &&
              _isSameDay(candidate.task.dueDate, nextDigestAt),
        )
        .toList(growable: false);
    if (dueOnDigestDay.isEmpty) return;

    await notificationService.scheduleReminder(
      id: digestId,
      title: 'Tasks due today',
      body: _digestBody(dueOnDigestDay),
      scheduledAt: nextDigestAt,
      kind: ReminderNotificationKind.taskDueTodayDigest,
    );
  }

  Future<void> _scheduleOverdueAlerts({
    required ReminderNotificationService notificationService,
    required List<_TaskNotificationCandidate> candidates,
    required NotificationSettingsPrefs prefs,
    required DateTime now,
  }) async {
    final scheduledAt = _nextOverdueAlertAt(now);

    for (final candidate in candidates) {
      final task = candidate.task;
      await notificationService.cancelReminder(_overdueId(task.id));

      if (!prefs.overdueAlertsEnabled ||
          candidate.isListArchived ||
          task.isDone ||
          !task.isOverdue) {
        continue;
      }

      await notificationService.scheduleReminder(
        id: _overdueId(task.id),
        title: 'Overdue task',
        body: task.title,
        scheduledAt: scheduledAt,
        repeatInterval: 'daily',
        kind: ReminderNotificationKind.taskOverdue,
      );
    }
  }

  List<_TaskNotificationCandidate> _taskCandidates(List<TaskListEntity> lists) {
    return [
      for (final list in lists)
        for (final task in list.tasks)
          _TaskNotificationCandidate(
            task: task,
            isListArchived: list.isArchived,
          ),
    ];
  }

  DateTime _nextDigestAt(DateTime now) {
    final todayAtEight = DateTime(now.year, now.month, now.day, 8);
    if (now.isBefore(todayAtEight)) return todayAtEight;
    final tomorrow = now.add(const Duration(days: 1));
    return DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 8);
  }

  DateTime _nextOverdueAlertAt(DateTime now) {
    final todayAtNine = DateTime(now.year, now.month, now.day, 9);
    if (now.isBefore(todayAtNine)) return todayAtNine;
    final tomorrow = now.add(const Duration(days: 1));
    return DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 9);
  }

  bool _isSameDay(DateTime? value, DateTime day) {
    return value != null &&
        value.year == day.year &&
        value.month == day.month &&
        value.day == day.day;
  }

  String _digestId(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return 'tasks_due_today_digest_${date.year}$month$day';
  }

  String _overdueId(String taskId) => 'task_overdue_$taskId';

  String _digestBody(List<_TaskNotificationCandidate> candidates) {
    final firstTitle = candidates.first.task.title.trim();
    if (candidates.length == 1) {
      return firstTitle.isEmpty
          ? '1 task is due today.'
          : '$firstTitle is due today.';
    }
    final remaining = candidates.length - 1;
    if (firstTitle.isEmpty) return '${candidates.length} tasks are due today.';
    return '$firstTitle and $remaining more are due today.';
  }
}

class _TaskNotificationCandidate {
  const _TaskNotificationCandidate({
    required this.task,
    required this.isListArchived,
  });

  final TaskEntity task;
  final bool isListArchived;
}
