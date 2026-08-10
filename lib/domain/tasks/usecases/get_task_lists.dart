import 'package:pass_doc_manager/core/usecase/usecase.dart';
import 'package:pass_doc_manager/domain/tasks/entities/task_list_entity.dart';
import 'package:pass_doc_manager/domain/tasks/repositories/task_repository.dart';

class GetTaskLists
    implements UseCase<List<TaskListEntity>, GetTaskListsParams> {
  GetTaskLists(this._repository);

  final TaskRepository _repository;

  @override
  Future<List<TaskListEntity>> call(GetTaskListsParams params) {
    return _repository.getTaskLists();
  }
}

class GetTaskListsParams {
  const GetTaskListsParams();
}
