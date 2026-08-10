import 'package:pass_doc_manager/core/usecase/usecase.dart';
import 'package:pass_doc_manager/domain/tasks/entities/task_list_entity.dart';
import 'package:pass_doc_manager/domain/tasks/repositories/task_repository.dart';

class SaveTaskList implements UseCase<TaskListEntity, SaveTaskListParams> {
  SaveTaskList(this._repository);

  final TaskRepository _repository;

  @override
  Future<TaskListEntity> call(SaveTaskListParams params) {
    return _repository.saveTaskList(params.list);
  }
}

class SaveTaskListParams {
  const SaveTaskListParams({required this.list});

  final TaskListEntity list;
}
