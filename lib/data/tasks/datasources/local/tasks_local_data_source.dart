import 'package:hive/hive.dart';
import 'package:pass_doc_manager/data/shared/storage/encrypted_hive_box_factory.dart';
import 'package:pass_doc_manager/data/tasks/dtos/task_record_dto.dart';

class TasksLocalDataSource {
  TasksLocalDataSource._({required Box<dynamic> box}) : _box = box;

  static const _boxName = 'credence_tasks_v1';
  static const _stateKey = 'tasks_state';

  final Box<dynamic> _box;

  static Future<TasksLocalDataSource> create() async {
    final box = await EncryptedHiveBoxFactory.openEncryptedBox(_boxName);
    return TasksLocalDataSource._(box: box);
  }

  Future<List<TaskListRecordDto>> getTaskLists() async {
    final normalized = _normalizeState(_box.get(_stateKey));
    final List<dynamic> rawList = normalized['items'] as List<dynamic>;
    return rawList
        .whereType<Map>()
        .map(
          (map) => TaskListRecordDto.fromMap(Map<String, dynamic>.from(map)),
        )
        .where((dto) => dto.id.trim().isNotEmpty)
        .toList(growable: false)
      ..sort((a, b) => b.updatedAtIso.compareTo(a.updatedAtIso));
  }

  Future<void> saveTaskLists(List<TaskListRecordDto> lists) async {
    await _box.put(_stateKey, {
      'items': lists.map((item) => item.toMap()).toList(growable: false),
    });
  }

  final Set<String> _generatedListIds = {};

  String nextListId() {
    final existing = _existingListIds()..addAll(_generatedListIds);
    var idx = existing.length + 1;
    var candidate = 'task_list_$idx';
    while (existing.contains(candidate)) {
      idx += 1;
      candidate = 'task_list_$idx';
    }
    _generatedListIds.add(candidate);
    return candidate;
  }

  final Set<String> _generatedTaskIds = {};

  String nextTaskId() {
    final existing = _existingTaskIds()..addAll(_generatedTaskIds);
    var idx = existing.length + 1;
    var candidate = 'task_$idx';
    while (existing.contains(candidate)) {
      idx += 1;
      candidate = 'task_$idx';
    }
    _generatedTaskIds.add(candidate);
    return candidate;
  }

  Set<String> _existingListIds() {
    final normalized = _normalizeState(_box.get(_stateKey));
    final List<dynamic> rawList = normalized['items'] as List<dynamic>;
    return rawList
        .whereType<Map>()
        .map((map) => '${map['id']}'.trim())
        .where((value) => value.isNotEmpty && value.toLowerCase() != 'null')
        .toSet();
  }

  Set<String> _existingTaskIds() {
    final normalized = _normalizeState(_box.get(_stateKey));
    final List<dynamic> rawLists = normalized['items'] as List<dynamic>;
    final ids = <String>{};
    for (final rawList in rawLists.whereType<Map>()) {
      final tasksRaw = rawList['tasks'];
      if (tasksRaw is! List) continue;
      for (final rawTask in tasksRaw.whereType<Map>()) {
        final id = '${rawTask['id']}'.trim();
        if (id.isEmpty || id.toLowerCase() == 'null') continue;
        ids.add(id);
      }
    }
    return ids;
  }

  Map<String, dynamic> _normalizeState(dynamic raw) {
    if (raw is Map<String, dynamic>) {
      final items = raw['items'];
      return {'items': items is List ? items : <dynamic>[]};
    }
    if (raw is Map) {
      final casted = Map<String, dynamic>.from(raw);
      final items = casted['items'];
      return {'items': items is List ? items : <dynamic>[]};
    }
    return {'items': <dynamic>[]};
  }
}
