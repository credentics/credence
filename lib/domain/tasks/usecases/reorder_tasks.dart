import 'package:pass_doc_manager/core/usecase/usecase.dart';
import 'package:pass_doc_manager/domain/tasks/entities/task_list_entity.dart';
import 'package:pass_doc_manager/domain/tasks/repositories/task_repository.dart';

class ReorderTasks implements UseCase<TaskListEntity, ReorderTasksParams> {
  ReorderTasks(this._repository);

  final TaskRepository _repository;

  @override
  Future<TaskListEntity> call(ReorderTasksParams params) {
    return _repository.reorderTasks(
      listId: params.listId,
      orderedTaskIds: params.orderedTaskIds,
    );
  }
}

class ReorderTasksParams {
  const ReorderTasksParams({
    required this.listId,
    required this.orderedTaskIds,
  });

  final String listId;
  final List<String> orderedTaskIds;
}
