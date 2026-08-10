import 'package:pass_doc_manager/domain/tasks/entities/task_entity.dart';
import 'package:pass_doc_manager/domain/tasks/entities/task_linked_ref.dart';
import 'package:pass_doc_manager/domain/tasks/entities/task_list_entity.dart';
import 'package:pass_doc_manager/domain/tasks/entities/task_priority.dart';

abstract class TaskRepository {
  Future<List<TaskListEntity>> getTaskLists();

  Future<TaskListEntity> getTaskListById({required String listId});

  Future<TaskListEntity> createTaskList({
    required String title,
    String? description,
    required String accentColorHex,
    required String iconKey,
  });

  /// Persists a whole list (title, description, archive flag). Caller is
  /// responsible for bumping `updatedAt` before calling. Tasks inside the
  /// list are mutated through the task-level methods, not this one.
  Future<TaskListEntity> saveTaskList(TaskListEntity list);

  Future<void> deleteTaskList({required String listId});

  Future<TaskEntity> createTask({
    required String listId,
    required String title,
    String? notes,
    DateTime? dueDate,
    TaskPriority priority,
    TaskLinkedRef? linkedRef,
    bool isPinned,
  });

  Future<TaskEntity> saveTask(TaskEntity task);

  /// Flips `isDone` and sets/clears `completedAt` accordingly.
  Future<TaskEntity> toggleTask({required String taskId});

  Future<void> deleteTask({required String taskId});

  /// Rewrites `position` for every task in the list in the given order.
  /// Tasks not included in [orderedTaskIds] are left at the tail in their
  /// existing relative order.
  Future<TaskListEntity> reorderTasks({
    required String listId,
    required List<String> orderedTaskIds,
  });
}
