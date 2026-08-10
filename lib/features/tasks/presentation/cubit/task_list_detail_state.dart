import 'package:pass_doc_manager/domain/tasks/entities/task_list_entity.dart';

enum TaskListDetailStatus { initial, loading, ready, error }

class TaskListDetailState {
  const TaskListDetailState({
    required this.status,
    required this.list,
    required this.showDone,
    required this.reorderMode,
    required this.errorMessage,
  });

  const TaskListDetailState.initial()
    : status = TaskListDetailStatus.initial,
      list = null,
      showDone = false,
      reorderMode = false,
      errorMessage = null;

  final TaskListDetailStatus status;
  final TaskListEntity? list;
  final bool showDone;

  /// In reorder mode the detail page shows a flat, drag-able list of open
  /// tasks sorted by `position` — section grouping is suspended so the
  /// user can rearrange without cross-section confusion.
  final bool reorderMode;

  final String? errorMessage;

  TaskListDetailState copyWith({
    TaskListDetailStatus? status,
    TaskListEntity? list,
    bool? showDone,
    bool? reorderMode,
    String? errorMessage,
    bool clearError = false,
  }) {
    return TaskListDetailState(
      status: status ?? this.status,
      list: list ?? this.list,
      showDone: showDone ?? this.showDone,
      reorderMode: reorderMode ?? this.reorderMode,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}
