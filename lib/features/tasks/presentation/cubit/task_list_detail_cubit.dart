import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pass_doc_manager/app/di/injection.dart';
import 'package:pass_doc_manager/domain/tasks/entities/task_entity.dart';
import 'package:pass_doc_manager/domain/tasks/entities/task_linked_ref.dart';
import 'package:pass_doc_manager/domain/tasks/entities/task_priority.dart';
import 'package:pass_doc_manager/domain/tasks/usecases/create_task.dart';
import 'package:pass_doc_manager/domain/tasks/usecases/delete_task.dart';
import 'package:pass_doc_manager/domain/tasks/usecases/get_task_list_detail.dart';
import 'package:pass_doc_manager/domain/tasks/usecases/reorder_tasks.dart';
import 'package:pass_doc_manager/domain/tasks/usecases/save_task.dart';
import 'package:pass_doc_manager/domain/tasks/usecases/toggle_task.dart';
import 'package:pass_doc_manager/features/tasks/infrastructure/services/task_notification_service.dart';
import 'package:pass_doc_manager/features/tasks/presentation/cubit/task_list_detail_state.dart';

class TaskListDetailCubit extends Cubit<TaskListDetailState> {
  TaskListDetailCubit({
    required this.listId,
    GetTaskListDetail? getDetail,
    CreateTask? createTask,
    SaveTask? saveTask,
    ToggleTask? toggleTask,
    DeleteTask? deleteTask,
    ReorderTasks? reorderTasks,
    TaskNotificationService? taskNotifications,
  }) : _getDetail = getDetail ?? getIt(),
       _createTask = createTask ?? getIt(),
       _saveTask = saveTask ?? getIt(),
       _toggleTask = toggleTask ?? getIt(),
       _deleteTask = deleteTask ?? getIt(),
       _reorderTasks = reorderTasks ?? getIt(),
       _taskNotifications = taskNotifications ?? getIt(),
       super(const TaskListDetailState.initial());

  final String listId;
  final GetTaskListDetail _getDetail;
  final CreateTask _createTask;
  final SaveTask _saveTask;
  final ToggleTask _toggleTask;
  final DeleteTask _deleteTask;
  final ReorderTasks _reorderTasks;
  final TaskNotificationService _taskNotifications;

  Future<void> load() async {
    emit(
      state.copyWith(status: TaskListDetailStatus.loading, clearError: true),
    );
    try {
      final list = await _getDetail(GetTaskListDetailParams(listId: listId));
      emit(
        state.copyWith(
          status: TaskListDetailStatus.ready,
          list: list,
          clearError: true,
        ),
      );
    } catch (error, stack) {
      debugPrint('[TaskListDetail] Failed to load: $error');
      debugPrintStack(stackTrace: stack);
      emit(state.copyWith(status: TaskListDetailStatus.error));
    }
  }

  Future<TaskEntity?> addTask({
    required String title,
    String? notes,
    DateTime? dueDate,
    TaskPriority priority = TaskPriority.low,
    TaskLinkedRef? linkedRef,
    bool isPinned = false,
  }) async {
    try {
      final created = await _createTask(
        CreateTaskParams(
          listId: listId,
          title: title,
          notes: notes,
          dueDate: dueDate,
          priority: priority,
          linkedRef: linkedRef,
          isPinned: isPinned,
        ),
      );
      await _refreshNotifications();
      await load();
      return created;
    } catch (error) {
      debugPrint('[TaskListDetail] Failed to add task: $error');
      return null;
    }
  }

  Future<void> updateTask(TaskEntity updated) async {
    try {
      await _saveTask(SaveTaskParams(task: updated));
      await _refreshNotifications();
      await load();
    } catch (error) {
      debugPrint('[TaskListDetail] Failed to save task: $error');
    }
  }

  Future<void> toggle(String taskId) async {
    try {
      await _toggleTask(ToggleTaskParams(taskId: taskId));
      await _refreshNotifications();
      await load();
    } catch (error) {
      debugPrint('[TaskListDetail] Failed to toggle: $error');
    }
  }

  Future<void> remove(String taskId) async {
    try {
      await _deleteTask(DeleteTaskParams(taskId: taskId));
      await _refreshNotifications();
      await load();
    } catch (error) {
      debugPrint('[TaskListDetail] Failed to delete: $error');
    }
  }

  Future<void> reorder(List<String> orderedTaskIds) async {
    try {
      await _reorderTasks(
        ReorderTasksParams(listId: listId, orderedTaskIds: orderedTaskIds),
      );
      await load();
    } catch (error) {
      debugPrint('[TaskListDetail] Failed to reorder: $error');
    }
  }

  void toggleShowDone() {
    emit(state.copyWith(showDone: !state.showDone));
  }

  void toggleReorderMode() {
    emit(state.copyWith(reorderMode: !state.reorderMode));
  }

  Future<void> refresh() => load();

  Future<void> _refreshNotifications() async {
    try {
      await _taskNotifications.scheduleTaskNotifications();
    } catch (error) {
      debugPrint('[TaskListDetail] Failed to refresh notifications: $error');
    }
  }
}
