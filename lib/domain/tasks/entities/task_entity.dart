import 'package:pass_doc_manager/domain/tasks/entities/task_linked_ref.dart';
import 'package:pass_doc_manager/domain/tasks/entities/task_priority.dart';

class TaskEntity {
  const TaskEntity({
    required this.id,
    required this.listId,
    required this.title,
    required this.notes,
    required this.isDone,
    required this.isPinned,
    required this.completedAt,
    required this.dueDate,
    required this.priority,
    required this.linkedRef,
    required this.position,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String listId;
  final String title;
  final String? notes;
  final bool isDone;
  final bool isPinned;
  final DateTime? completedAt;
  final DateTime? dueDate;
  final TaskPriority priority;
  final TaskLinkedRef? linkedRef;

  /// User-visible ordering within the parent list.
  final int position;

  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isOverdue =>
      !isDone && dueDate != null && dueDate!.isBefore(_todayStart());

  bool get isDueToday {
    if (isDone || dueDate == null) return false;
    final start = _todayStart();
    final end = start.add(const Duration(days: 1));
    return !dueDate!.isBefore(start) && dueDate!.isBefore(end);
  }

  TaskEntity copyWith({
    String? id,
    String? listId,
    String? title,
    String? notes,
    bool clearNotes = false,
    bool? isDone,
    bool? isPinned,
    DateTime? completedAt,
    bool clearCompletedAt = false,
    DateTime? dueDate,
    bool clearDueDate = false,
    TaskPriority? priority,
    TaskLinkedRef? linkedRef,
    bool clearLinkedRef = false,
    int? position,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TaskEntity(
      id: id ?? this.id,
      listId: listId ?? this.listId,
      title: title ?? this.title,
      notes: clearNotes ? null : (notes ?? this.notes),
      isDone: isDone ?? this.isDone,
      isPinned: isPinned ?? this.isPinned,
      completedAt:
          clearCompletedAt ? null : (completedAt ?? this.completedAt),
      dueDate: clearDueDate ? null : (dueDate ?? this.dueDate),
      priority: priority ?? this.priority,
      linkedRef: clearLinkedRef ? null : (linkedRef ?? this.linkedRef),
      position: position ?? this.position,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  static DateTime _todayStart() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }
}
