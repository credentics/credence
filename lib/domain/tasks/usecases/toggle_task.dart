import 'package:pass_doc_manager/core/usecase/usecase.dart';
import 'package:pass_doc_manager/domain/tasks/entities/task_entity.dart';
import 'package:pass_doc_manager/domain/tasks/repositories/task_repository.dart';

class ToggleTask implements UseCase<TaskEntity, ToggleTaskParams> {
  ToggleTask(this._repository);

  final TaskRepository _repository;

  @override
  Future<TaskEntity> call(ToggleTaskParams params) {
    return _repository.toggleTask(taskId: params.taskId);
  }
}

class ToggleTaskParams {
  const ToggleTaskParams({required this.taskId});

  final String taskId;
}
