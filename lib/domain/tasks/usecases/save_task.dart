import 'package:pass_doc_manager/core/usecase/usecase.dart';
import 'package:pass_doc_manager/domain/tasks/entities/task_entity.dart';
import 'package:pass_doc_manager/domain/tasks/repositories/task_repository.dart';

class SaveTask implements UseCase<TaskEntity, SaveTaskParams> {
  SaveTask(this._repository);

  final TaskRepository _repository;

  @override
  Future<TaskEntity> call(SaveTaskParams params) {
    return _repository.saveTask(params.task);
  }
}

class SaveTaskParams {
  const SaveTaskParams({required this.task});

  final TaskEntity task;
}
