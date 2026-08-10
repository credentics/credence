import 'package:pass_doc_manager/data/tasks/datasources/local/tasks_local_data_source.dart';
import 'package:pass_doc_manager/data/tasks/dtos/task_record_dto.dart';
import 'package:pass_doc_manager/domain/tasks/entities/task_entity.dart';
import 'package:pass_doc_manager/domain/tasks/entities/task_linked_ref.dart';
import 'package:pass_doc_manager/domain/tasks/entities/task_list_entity.dart';
import 'package:pass_doc_manager/domain/tasks/entities/task_priority.dart';
import 'package:pass_doc_manager/domain/tasks/repositories/task_repository.dart';

class TasksRepositoryImpl implements TaskRepository {
  const TasksRepositoryImpl({required this.localDataSource});

  final TasksLocalDataSource localDataSource;

  @override
  Future<List<TaskListEntity>> getTaskLists() async {
    final records = await localDataSource.getTaskLists();
    return records.map(_toEntity).toList(growable: false)
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  @override
  Future<TaskListEntity> getTaskListById({required String listId}) async {
    final records = await localDataSource.getTaskLists();
    final match = _findListById(records, listId);
    if (match == null) {
      throw StateError('Task list not found: $listId');
    }
    return _toEntity(match);
  }

  @override
  Future<TaskListEntity> createTaskList({
    required String title,
    String? description,
    required String accentColorHex,
    required String iconKey,
  }) async {
    final now = DateTime.now();
    final records = await localDataSource.getTaskLists();
    final id = localDataSource.nextListId();
    final record = TaskListRecordDto(
      id: id,
      title: title,
      description: _nullIfBlank(description),
      accentColorHex: accentColorHex,
      iconKey: iconKey,
      isArchived: false,
      createdAtIso: now.toIso8601String(),
      updatedAtIso: now.toIso8601String(),
      tasks: const [],
    );
    await localDataSource.saveTaskLists([...records, record]);
    return _toEntity(record);
  }

  @override
  Future<TaskListEntity> saveTaskList(TaskListEntity list) async {
    final records = await localDataSource.getTaskLists();
    final existing = _findListById(records, list.id);
    if (existing == null) {
      throw StateError('Task list not found: ${list.id}');
    }
    // Preserve the existing task records — only list-level fields are
    // editable through this method.
    final updated = TaskListRecordDto(
      id: existing.id,
      title: list.title,
      description: _nullIfBlank(list.description),
      accentColorHex: list.accentColorHex,
      iconKey: list.iconKey,
      isArchived: list.isArchived,
      createdAtIso: existing.createdAtIso,
      updatedAtIso: DateTime.now().toIso8601String(),
      tasks: existing.tasks,
    );
    await localDataSource.saveTaskLists(
      records
          .map((record) => record.id == list.id ? updated : record)
          .toList(growable: false),
    );
    return _toEntity(updated);
  }

  @override
  Future<void> deleteTaskList({required String listId}) async {
    final records = await localDataSource.getTaskLists();
    final filtered = records
        .where((record) => record.id != listId)
        .toList(growable: false);
    if (filtered.length == records.length) return;
    await localDataSource.saveTaskLists(filtered);
  }

  @override
  Future<TaskEntity> createTask({
    required String listId,
    required String title,
    String? notes,
    DateTime? dueDate,
    TaskPriority priority = TaskPriority.low,
    TaskLinkedRef? linkedRef,
    bool isPinned = false,
  }) async {
    final records = await localDataSource.getTaskLists();
    final existing = _findListById(records, listId);
    if (existing == null) {
      throw StateError('Task list not found: $listId');
    }

    final now = DateTime.now();
    final taskId = localDataSource.nextTaskId();
    final maxPos = existing.tasks.fold<int>(
      -1,
      (acc, t) => t.position > acc ? t.position : acc,
    );
    final record = TaskRecordDto(
      id: taskId,
      listId: listId,
      title: title,
      notes: _nullIfBlank(notes),
      isDone: false,
      isPinned: isPinned,
      completedAtIso: null,
      dueAtIso: dueDate?.toIso8601String(),
      priorityKey: priority.storageKey,
      linkedRef: linkedRef == null
          ? null
          : TaskLinkedRefRecordDto(
              type: linkedRef.type,
              refId: linkedRef.refId,
              displayName: linkedRef.displayNameSnapshot,
            ),
      position: maxPos + 1,
      createdAtIso: now.toIso8601String(),
      updatedAtIso: now.toIso8601String(),
    );

    final updatedList = TaskListRecordDto(
      id: existing.id,
      title: existing.title,
      description: existing.description,
      accentColorHex: existing.accentColorHex,
      iconKey: existing.iconKey,
      isArchived: existing.isArchived,
      createdAtIso: existing.createdAtIso,
      updatedAtIso: now.toIso8601String(),
      tasks: [...existing.tasks, record],
    );

    await localDataSource.saveTaskLists(
      records
          .map((item) => item.id == listId ? updatedList : item)
          .toList(growable: false),
    );

    return _toTaskEntity(record);
  }

  @override
  Future<TaskEntity> saveTask(TaskEntity task) async {
    final records = await localDataSource.getTaskLists();
    final existing = _findListById(records, task.listId);
    if (existing == null) {
      throw StateError('Task list not found: ${task.listId}');
    }

    final now = DateTime.now();
    final updatedTaskRecord = _fromTaskEntity(
      task.copyWith(updatedAt: now),
    );
    final updatedList = TaskListRecordDto(
      id: existing.id,
      title: existing.title,
      description: existing.description,
      accentColorHex: existing.accentColorHex,
      iconKey: existing.iconKey,
      isArchived: existing.isArchived,
      createdAtIso: existing.createdAtIso,
      updatedAtIso: now.toIso8601String(),
      tasks: existing.tasks
          .map((t) => t.id == task.id ? updatedTaskRecord : t)
          .toList(growable: false),
    );

    await localDataSource.saveTaskLists(
      records
          .map((item) => item.id == task.listId ? updatedList : item)
          .toList(growable: false),
    );

    return _toTaskEntity(updatedTaskRecord);
  }

  @override
  Future<TaskEntity> toggleTask({required String taskId}) async {
    final records = await localDataSource.getTaskLists();
    final listRecord = _findListContainingTask(records, taskId);
    if (listRecord == null) {
      throw StateError('Task not found: $taskId');
    }
    final existingTask = listRecord.tasks.firstWhere((t) => t.id == taskId);
    final now = DateTime.now();
    final nextIsDone = !existingTask.isDone;
    final updatedTask = TaskRecordDto(
      id: existingTask.id,
      listId: existingTask.listId,
      title: existingTask.title,
      notes: existingTask.notes,
      isDone: nextIsDone,
      isPinned: existingTask.isPinned,
      completedAtIso: nextIsDone ? now.toIso8601String() : null,
      dueAtIso: existingTask.dueAtIso,
      priorityKey: existingTask.priorityKey,
      linkedRef: existingTask.linkedRef,
      position: existingTask.position,
      createdAtIso: existingTask.createdAtIso,
      updatedAtIso: now.toIso8601String(),
    );

    final updatedList = TaskListRecordDto(
      id: listRecord.id,
      title: listRecord.title,
      description: listRecord.description,
      accentColorHex: listRecord.accentColorHex,
      iconKey: listRecord.iconKey,
      isArchived: listRecord.isArchived,
      createdAtIso: listRecord.createdAtIso,
      updatedAtIso: now.toIso8601String(),
      tasks: listRecord.tasks
          .map((t) => t.id == taskId ? updatedTask : t)
          .toList(growable: false),
    );

    await localDataSource.saveTaskLists(
      records
          .map((item) => item.id == listRecord.id ? updatedList : item)
          .toList(growable: false),
    );

    return _toTaskEntity(updatedTask);
  }

  @override
  Future<void> deleteTask({required String taskId}) async {
    final records = await localDataSource.getTaskLists();
    final listRecord = _findListContainingTask(records, taskId);
    if (listRecord == null) return;
    final now = DateTime.now();
    final filtered = listRecord.tasks
        .where((t) => t.id != taskId)
        .toList(growable: false);
    final updatedList = TaskListRecordDto(
      id: listRecord.id,
      title: listRecord.title,
      description: listRecord.description,
      accentColorHex: listRecord.accentColorHex,
      iconKey: listRecord.iconKey,
      isArchived: listRecord.isArchived,
      createdAtIso: listRecord.createdAtIso,
      updatedAtIso: now.toIso8601String(),
      tasks: filtered,
    );
    await localDataSource.saveTaskLists(
      records
          .map((item) => item.id == listRecord.id ? updatedList : item)
          .toList(growable: false),
    );
  }

  @override
  Future<TaskListEntity> reorderTasks({
    required String listId,
    required List<String> orderedTaskIds,
  }) async {
    final records = await localDataSource.getTaskLists();
    final existing = _findListById(records, listId);
    if (existing == null) {
      throw StateError('Task list not found: $listId');
    }

    final positionByKey = <String, int>{};
    for (var i = 0; i < orderedTaskIds.length; i++) {
      positionByKey[orderedTaskIds[i]] = i;
    }

    final reordered = existing.tasks
        .map((task) {
          final pos = positionByKey[task.id];
          if (pos == null) return task;
          return TaskRecordDto(
            id: task.id,
            listId: task.listId,
            title: task.title,
            notes: task.notes,
            isDone: task.isDone,
            isPinned: task.isPinned,
            completedAtIso: task.completedAtIso,
            dueAtIso: task.dueAtIso,
            priorityKey: task.priorityKey,
            linkedRef: task.linkedRef,
            position: pos,
            createdAtIso: task.createdAtIso,
            updatedAtIso: task.updatedAtIso,
          );
        })
        .toList(growable: false)
      ..sort((a, b) => a.position.compareTo(b.position));

    final now = DateTime.now();
    final updatedList = TaskListRecordDto(
      id: existing.id,
      title: existing.title,
      description: existing.description,
      accentColorHex: existing.accentColorHex,
      iconKey: existing.iconKey,
      isArchived: existing.isArchived,
      createdAtIso: existing.createdAtIso,
      updatedAtIso: now.toIso8601String(),
      tasks: reordered,
    );

    await localDataSource.saveTaskLists(
      records
          .map((item) => item.id == listId ? updatedList : item)
          .toList(growable: false),
    );

    return _toEntity(updatedList);
  }

  // ---------------------------------------------------------------------------
  // Mapping

  TaskListEntity _toEntity(TaskListRecordDto dto) {
    return TaskListEntity(
      id: dto.id,
      title: dto.title,
      description: dto.description,
      accentColorHex: dto.accentColorHex,
      iconKey: dto.iconKey,
      isArchived: dto.isArchived,
      createdAt: _parseDate(dto.createdAtIso) ?? DateTime.now(),
      updatedAt: _parseDate(dto.updatedAtIso) ?? DateTime.now(),
      tasks: dto.tasks.map(_toTaskEntity).toList(growable: false)
        ..sort((a, b) => a.position.compareTo(b.position)),
    );
  }

  TaskEntity _toTaskEntity(TaskRecordDto dto) {
    final linked = dto.linkedRef;
    return TaskEntity(
      id: dto.id,
      listId: dto.listId,
      title: dto.title,
      notes: dto.notes,
      isDone: dto.isDone,
      isPinned: dto.isPinned,
      completedAt: _parseDate(dto.completedAtIso),
      dueDate: _parseDate(dto.dueAtIso),
      priority: TaskPriority.fromStorageKey(dto.priorityKey),
      linkedRef: linked == null
          ? null
          : TaskLinkedRef(
              type: linked.type,
              refId: linked.refId,
              displayNameSnapshot: linked.displayName,
            ),
      position: dto.position,
      createdAt: _parseDate(dto.createdAtIso) ?? DateTime.now(),
      updatedAt: _parseDate(dto.updatedAtIso) ?? DateTime.now(),
    );
  }

  TaskRecordDto _fromTaskEntity(TaskEntity entity) {
    return TaskRecordDto(
      id: entity.id,
      listId: entity.listId,
      title: entity.title,
      notes: _nullIfBlank(entity.notes),
      isDone: entity.isDone,
      isPinned: entity.isPinned,
      completedAtIso: entity.completedAt?.toIso8601String(),
      dueAtIso: entity.dueDate?.toIso8601String(),
      priorityKey: entity.priority.storageKey,
      linkedRef: entity.linkedRef == null
          ? null
          : TaskLinkedRefRecordDto(
              type: entity.linkedRef!.type,
              refId: entity.linkedRef!.refId,
              displayName: entity.linkedRef!.displayNameSnapshot,
            ),
      position: entity.position,
      createdAtIso: entity.createdAt.toIso8601String(),
      updatedAtIso: entity.updatedAt.toIso8601String(),
    );
  }

  // ---------------------------------------------------------------------------
  // Helpers

  TaskListRecordDto? _findListById(
    List<TaskListRecordDto> records,
    String id,
  ) {
    for (final record in records) {
      if (record.id == id) return record;
    }
    return null;
  }

  TaskListRecordDto? _findListContainingTask(
    List<TaskListRecordDto> records,
    String taskId,
  ) {
    for (final record in records) {
      for (final task in record.tasks) {
        if (task.id == taskId) return record;
      }
    }
    return null;
  }

  DateTime? _parseDate(String? iso) {
    if (iso == null || iso.isEmpty) return null;
    return DateTime.tryParse(iso);
  }

  String? _nullIfBlank(String? value) {
    if (value == null) return null;
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}
