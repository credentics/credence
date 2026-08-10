import 'package:pass_doc_manager/core/usecase/usecase.dart';
import 'package:pass_doc_manager/domain/tasks/entities/task_entity.dart';
import 'package:pass_doc_manager/domain/tasks/entities/task_linked_ref.dart';
import 'package:pass_doc_manager/domain/tasks/entities/task_priority.dart';
import 'package:pass_doc_manager/domain/tasks/repositories/task_repository.dart';

class CreateTask implements UseCase<TaskEntity, CreateTaskParams> {
  CreateTask(this._repository);

  final TaskRepository _repository;

  @override
  Future<TaskEntity> call(CreateTaskParams params) {
    return _repository.createTask(
      listId: params.listId,
      title: params.title,
      notes: params.notes,
      dueDate: params.dueDate,
      priority: params.priority,
      linkedRef: params.linkedRef,
      isPinned: params.isPinned,
    );
  }
}

class CreateTaskParams {
  const CreateTaskParams({
    required this.listId,
    required this.title,
    this.notes,
    this.dueDate,
    this.priority = TaskPriority.low,
    this.linkedRef,
    this.isPinned = false,
  });

  final String listId;
  final String title;
  final String? notes;
  final DateTime? dueDate;
  final TaskPriority priority;
  final TaskLinkedRef? linkedRef;
  final bool isPinned;
}
