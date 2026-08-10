import 'package:pass_doc_manager/core/usecase/usecase.dart';
import 'package:pass_doc_manager/domain/tasks/repositories/task_repository.dart';

class DeleteTask implements UseCase<void, DeleteTaskParams> {
  DeleteTask(this._repository);

  final TaskRepository _repository;

  @override
  Future<void> call(DeleteTaskParams params) {
    return _repository.deleteTask(taskId: params.taskId);
  }
}

class DeleteTaskParams {
  const DeleteTaskParams({required this.taskId});

  final String taskId;
}
