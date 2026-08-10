import 'package:pass_doc_manager/core/usecase/usecase.dart';
import 'package:pass_doc_manager/domain/tasks/repositories/task_repository.dart';

class DeleteTaskList implements UseCase<void, DeleteTaskListParams> {
  DeleteTaskList(this._repository);

  final TaskRepository _repository;

  @override
  Future<void> call(DeleteTaskListParams params) {
    return _repository.deleteTaskList(listId: params.listId);
  }
}

class DeleteTaskListParams {
  const DeleteTaskListParams({required this.listId});

  final String listId;
}
