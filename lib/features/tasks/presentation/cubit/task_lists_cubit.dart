import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pass_doc_manager/app/di/injection.dart';
import 'package:pass_doc_manager/domain/tasks/entities/task_list_entity.dart';
import 'package:pass_doc_manager/domain/tasks/usecases/create_task_list.dart';
import 'package:pass_doc_manager/domain/tasks/usecases/delete_task_list.dart';
import 'package:pass_doc_manager/domain/tasks/usecases/get_task_lists.dart';
import 'package:pass_doc_manager/domain/tasks/usecases/save_task_list.dart';
import 'package:pass_doc_manager/domain/tasks/usecases/toggle_task.dart';
import 'package:pass_doc_manager/features/tasks/infrastructure/services/task_notification_service.dart';
import 'package:pass_doc_manager/features/tasks/presentation/cubit/task_lists_state.dart';

class TaskListsCubit extends Cubit<TaskListsState> {
  TaskListsCubit({
    GetTaskLists? getTaskLists,
    CreateTaskList? createTaskList,
    SaveTaskList? saveTaskList,
    DeleteTaskList? deleteTaskList,
    ToggleTask? toggleTask,
    TaskNotificationService? taskNotifications,
  }) : _getTaskLists = getTaskLists ?? getIt(),
       _createTaskList = createTaskList ?? getIt(),
       _saveTaskList = saveTaskList ?? getIt(),
       _deleteTaskList = deleteTaskList ?? getIt(),
       _toggleTask = toggleTask ?? getIt(),
       _taskNotifications = taskNotifications ?? getIt(),
       super(const TaskListsState.initial());

  final GetTaskLists _getTaskLists;
  final CreateTaskList _createTaskList;
  final SaveTaskList _saveTaskList;
  final DeleteTaskList _deleteTaskList;
  final ToggleTask _toggleTask;
  final TaskNotificationService _taskNotifications;

  Future<void> load() async {
    emit(state.copyWith(status: TaskListsStatus.loading, clearError: true));
    try {
      final items = await _getTaskLists(const GetTaskListsParams());
      emit(
        state.copyWith(
          status: TaskListsStatus.ready,
          lists: items,
          clearError: true,
        ),
      );
    } catch (error, stack) {
      debugPrint('[Tasks] Failed to load: $error');
      debugPrintStack(stackTrace: stack);
      emit(state.copyWith(status: TaskListsStatus.error));
    }
  }

  Future<TaskListEntity?> create({
    required String title,
    String? description,
    required String accentColorHex,
    required String iconKey,
  }) async {
    try {
      final created = await _createTaskList(
        CreateTaskListParams(
          title: title,
          description: description,
          accentColorHex: accentColorHex,
          iconKey: iconKey,
        ),
      );
      await load();
      return created;
    } catch (error) {
      debugPrint('[Tasks] Failed to create: $error');
      return null;
    }
  }

  Future<void> setArchived(TaskListEntity list, bool isArchived) async {
    try {
      await _saveTaskList(
        SaveTaskListParams(list: list.copyWith(isArchived: isArchived)),
      );
      await _refreshNotifications();
      await load();
    } catch (error) {
      debugPrint('[Tasks] Failed to archive: $error');
    }
  }

  Future<void> delete(String listId) async {
    try {
      await _deleteTaskList(DeleteTaskListParams(listId: listId));
      await _refreshNotifications();
      await load();
    } catch (error) {
      debugPrint('[Tasks] Failed to delete: $error');
    }
  }

  Future<void> toggleTask(String taskId) async {
    try {
      await _toggleTask(ToggleTaskParams(taskId: taskId));
      await _refreshNotifications();
      await load();
    } catch (error) {
      debugPrint('[Tasks] Failed to toggle task: $error');
    }
  }

  void toggleShowArchived() {
    emit(state.copyWith(showArchived: !state.showArchived));
  }

  Future<void> _refreshNotifications() async {
    try {
      await _taskNotifications.scheduleTaskNotifications();
    } catch (error) {
      debugPrint('[Tasks] Failed to refresh notifications: $error');
    }
  }
}
