import 'package:pass_doc_manager/domain/tasks/entities/task_entity.dart';

class TaskListEntity {
  const TaskListEntity({
    required this.id,
    required this.title,
    required this.description,
    required this.accentColorHex,
    required this.iconKey,
    required this.isArchived,
    required this.createdAt,
    required this.updatedAt,
    required this.tasks,
  });

  final String id;
  final String title;
  final String? description;
  final String accentColorHex;
  final String iconKey;
  final bool isArchived;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<TaskEntity> tasks;

  int get totalCount => tasks.length;
  int get doneCount => tasks.where((t) => t.isDone).length;
  int get openCount => totalCount - doneCount;
  int get overdueCount => tasks.where((t) => t.isOverdue).length;
  int get pinnedOpenCount =>
      tasks.where((t) => t.isPinned && !t.isDone).length;

  /// Progress as 0.0 – 1.0. Returns 0 when the list is empty to avoid NaN.
  double get progress {
    if (totalCount == 0) return 0;
    return doneCount / totalCount;
  }

  TaskListEntity copyWith({
    String? id,
    String? title,
    String? description,
    bool clearDescription = false,
    String? accentColorHex,
    String? iconKey,
    bool? isArchived,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<TaskEntity>? tasks,
  }) {
    return TaskListEntity(
      id: id ?? this.id,
      title: title ?? this.title,
      description:
          clearDescription ? null : (description ?? this.description),
      accentColorHex: accentColorHex ?? this.accentColorHex,
      iconKey: iconKey ?? this.iconKey,
      isArchived: isArchived ?? this.isArchived,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      tasks: tasks ?? this.tasks,
    );
  }
}
