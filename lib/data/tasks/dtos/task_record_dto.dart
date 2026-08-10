class TaskListRecordDto {
  const TaskListRecordDto({
    required this.id,
    required this.title,
    required this.description,
    required this.accentColorHex,
    required this.iconKey,
    required this.isArchived,
    required this.createdAtIso,
    required this.updatedAtIso,
    required this.tasks,
  });

  factory TaskListRecordDto.fromMap(Map<String, dynamic> map) {
    final tasksRaw = map['tasks'];
    return TaskListRecordDto(
      id: _asString(map['id']),
      title: _asString(map['title']),
      description: _nullableString(map['description']),
      accentColorHex: _asString(map['accent_color_hex']),
      iconKey: _asString(map['icon_key']),
      isArchived: map['is_archived'] == true,
      createdAtIso: _asString(map['created_at_iso']),
      updatedAtIso: _asString(map['updated_at_iso']),
      tasks: tasksRaw is List
          ? tasksRaw
                .whereType<Map>()
                .map(
                  (raw) => TaskRecordDto.fromMap(
                    Map<String, dynamic>.from(raw),
                  ),
                )
                .toList(growable: false)
          : const <TaskRecordDto>[],
    );
  }

  final String id;
  final String title;
  final String? description;
  final String accentColorHex;
  final String iconKey;
  final bool isArchived;
  final String createdAtIso;
  final String updatedAtIso;
  final List<TaskRecordDto> tasks;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'accent_color_hex': accentColorHex,
      'icon_key': iconKey,
      'is_archived': isArchived,
      'created_at_iso': createdAtIso,
      'updated_at_iso': updatedAtIso,
      'tasks': tasks.map((task) => task.toMap()).toList(growable: false),
    };
  }
}

class TaskRecordDto {
  const TaskRecordDto({
    required this.id,
    required this.listId,
    required this.title,
    required this.notes,
    required this.isDone,
    required this.isPinned,
    required this.completedAtIso,
    required this.dueAtIso,
    required this.priorityKey,
    required this.linkedRef,
    required this.position,
    required this.createdAtIso,
    required this.updatedAtIso,
  });

  factory TaskRecordDto.fromMap(Map<String, dynamic> map) {
    final rawLinked = map['linked_ref'];
    return TaskRecordDto(
      id: _asString(map['id']),
      listId: _asString(map['list_id']),
      title: _asString(map['title']),
      notes: _nullableString(map['notes']),
      isDone: map['is_done'] == true,
      isPinned: map['is_pinned'] == true,
      completedAtIso: _nullableString(map['completed_at_iso']),
      dueAtIso: _nullableString(map['due_at_iso']),
      priorityKey: _asString(map['priority_key']),
      linkedRef: rawLinked is Map
          ? TaskLinkedRefRecordDto.fromMap(
              Map<String, dynamic>.from(rawLinked),
            )
          : null,
      position: _asInt(map['position']),
      createdAtIso: _asString(map['created_at_iso']),
      updatedAtIso: _asString(map['updated_at_iso']),
    );
  }

  final String id;
  final String listId;
  final String title;
  final String? notes;
  final bool isDone;
  final bool isPinned;
  final String? completedAtIso;
  final String? dueAtIso;
  final String priorityKey;
  final TaskLinkedRefRecordDto? linkedRef;
  final int position;
  final String createdAtIso;
  final String updatedAtIso;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'list_id': listId,
      'title': title,
      'notes': notes,
      'is_done': isDone,
      'is_pinned': isPinned,
      'completed_at_iso': completedAtIso,
      'due_at_iso': dueAtIso,
      'priority_key': priorityKey,
      'linked_ref': linkedRef?.toMap(),
      'position': position,
      'created_at_iso': createdAtIso,
      'updated_at_iso': updatedAtIso,
    };
  }
}

class TaskLinkedRefRecordDto {
  const TaskLinkedRefRecordDto({
    required this.type,
    required this.refId,
    required this.displayName,
  });

  factory TaskLinkedRefRecordDto.fromMap(Map<String, dynamic> map) {
    return TaskLinkedRefRecordDto(
      type: _asString(map['type']),
      refId: _asString(map['ref_id']),
      displayName: _asString(map['display_name']),
    );
  }

  final String type;
  final String refId;
  final String displayName;

  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'ref_id': refId,
      'display_name': displayName,
    };
  }
}

String _asString(dynamic value) {
  final resolved = '$value'.trim();
  if (resolved.toLowerCase() == 'null') return '';
  return resolved;
}

String? _nullableString(dynamic value) {
  final resolved = _asString(value);
  return resolved.isEmpty ? null : resolved;
}

int _asInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse('$value') ?? 0;
}
