import 'package:pass_doc_manager/domain/tasks/entities/task_list_entity.dart';

enum TaskListsStatus { initial, loading, ready, error }

class TaskListsState {
  const TaskListsState({
    required this.status,
    required this.lists,
    required this.showArchived,
    required this.errorMessage,
  });

  const TaskListsState.initial()
    : status = TaskListsStatus.initial,
      lists = const <TaskListEntity>[],
      showArchived = false,
      errorMessage = null;

  final TaskListsStatus status;
  final List<TaskListEntity> lists;
  final bool showArchived;
  final String? errorMessage;

  List<TaskListEntity> get visibleLists => showArchived
      ? lists
      : lists.where((l) => !l.isArchived).toList(growable: false);

  TaskListsState copyWith({
    TaskListsStatus? status,
    List<TaskListEntity>? lists,
    bool? showArchived,
    String? errorMessage,
    bool clearError = false,
  }) {
    return TaskListsState(
      status: status ?? this.status,
      lists: lists ?? this.lists,
      showArchived: showArchived ?? this.showArchived,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}
