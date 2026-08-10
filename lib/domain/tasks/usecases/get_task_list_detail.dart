import 'package:pass_doc_manager/core/usecase/usecase.dart';
import 'package:pass_doc_manager/domain/tasks/entities/task_list_entity.dart';
import 'package:pass_doc_manager/domain/tasks/repositories/task_repository.dart';

class GetTaskListDetail
    implements UseCase<TaskListEntity, GetTaskListDetailParams> {
  GetTaskListDetail(this._repository);

  final TaskRepository _repository;

  @override
  Future<TaskListEntity> call(GetTaskListDetailParams params) {
    return _repository.getTaskListById(listId: params.listId);
  }
}

class GetTaskListDetailParams {
  const GetTaskListDetailParams({required this.listId});

  final String listId;
}
