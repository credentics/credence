import 'package:pass_doc_manager/core/usecase/usecase.dart';
import 'package:pass_doc_manager/domain/tasks/entities/task_list_entity.dart';
import 'package:pass_doc_manager/domain/tasks/repositories/task_repository.dart';

class CreateTaskList
    implements UseCase<TaskListEntity, CreateTaskListParams> {
  CreateTaskList(this._repository);

  final TaskRepository _repository;

  @override
  Future<TaskListEntity> call(CreateTaskListParams params) {
    return _repository.createTaskList(
      title: params.title,
      description: params.description,
      accentColorHex: params.accentColorHex,
      iconKey: params.iconKey,
    );
  }
}

class CreateTaskListParams {
  const CreateTaskListParams({
    required this.title,
    this.description,
    required this.accentColorHex,
    required this.iconKey,
  });

  final String title;
  final String? description;
  final String accentColorHex;
  final String iconKey;
}
