class BundleRecordDto {
  const BundleRecordDto({
    required this.id,
    required this.title,
    required this.purpose,
    required this.description,
    required this.templateKey,
    required this.statusKey,
    required this.items,
    required this.history,
    required this.createdAtIso,
    required this.updatedAtIso,
    required this.lastExportedAtIso,
    required this.lastExportPath,
  });

  factory BundleRecordDto.fromMap(Map<String, dynamic> map) {
    final itemsRaw = map['items'];
    final historyRaw = map['history'];
    return BundleRecordDto(
      id: _asString(map['id']),
      title: _asString(map['title']),
      purpose: _nullableString(map['purpose']),
      description: _nullableString(map['description']),
      templateKey: _nullableString(map['template_key']),
      statusKey: _asString(map['status_key']),
      items: itemsRaw is List
          ? itemsRaw
                .whereType<Map>()
                .map(
                  (raw) => BundleItemRecordDto.fromMap(
                    Map<String, dynamic>.from(raw),
                  ),
                )
                .toList(growable: false)
          : const <BundleItemRecordDto>[],
      history: historyRaw is List
          ? historyRaw
                .whereType<Map>()
                .map(
                  (raw) => BundleEventRecordDto.fromMap(
                    Map<String, dynamic>.from(raw),
                  ),
                )
                .toList(growable: false)
          : const <BundleEventRecordDto>[],
      createdAtIso: _asString(map['created_at_iso']),
      updatedAtIso: _asString(map['updated_at_iso']),
      lastExportedAtIso: _nullableString(map['last_exported_at_iso']),
      lastExportPath: _nullableString(map['last_export_path']),
    );
  }

  final String id;
  final String title;
  final String? purpose;
  final String? description;
  final String? templateKey;
  final String statusKey;
  final List<BundleItemRecordDto> items;
  final List<BundleEventRecordDto> history;
  final String createdAtIso;
  final String updatedAtIso;
  final String? lastExportedAtIso;
  final String? lastExportPath;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'purpose': purpose,
      'description': description,
      'template_key': templateKey,
      'status_key': statusKey,
      'items': items.map((item) => item.toMap()).toList(growable: false),
      'history': history.map((event) => event.toMap()).toList(growable: false),
      'created_at_iso': createdAtIso,
      'updated_at_iso': updatedAtIso,
      'last_exported_at_iso': lastExportedAtIso,
      'last_export_path': lastExportPath,
    };
  }
}

class BundleItemRecordDto {
  const BundleItemRecordDto({
    required this.id,
    required this.typeKey,
    required this.refId,
    required this.displayName,
    required this.subtitle,
    required this.addedAtIso,
  });

  factory BundleItemRecordDto.fromMap(Map<String, dynamic> map) {
    return BundleItemRecordDto(
      id: _asString(map['id']),
      typeKey: _asString(map['type_key']),
      refId: _asString(map['ref_id']),
      displayName: _asString(map['display_name']),
      subtitle: _nullableString(map['subtitle']),
      addedAtIso: _asString(map['added_at_iso']),
    );
  }

  final String id;
  final String typeKey;
  final String refId;
  final String displayName;
  final String? subtitle;
  final String addedAtIso;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type_key': typeKey,
      'ref_id': refId,
      'display_name': displayName,
      'subtitle': subtitle,
      'added_at_iso': addedAtIso,
    };
  }
}

class BundleEventRecordDto {
  const BundleEventRecordDto({
    required this.id,
    required this.kindKey,
    required this.atIso,
    required this.detail,
  });

  factory BundleEventRecordDto.fromMap(Map<String, dynamic> map) {
    return BundleEventRecordDto(
      id: _asString(map['id']),
      kindKey: _asString(map['kind_key']),
      atIso: _asString(map['at_iso']),
      detail: _nullableString(map['detail']),
    );
  }

  final String id;
  final String kindKey;
  final String atIso;
  final String? detail;

  Map<String, dynamic> toMap() {
    return {'id': id, 'kind_key': kindKey, 'at_iso': atIso, 'detail': detail};
  }
}

String _asString(dynamic value) {
  final resolved = '$value'.trim();
  if (resolved.toLowerCase() == 'null') {
    return '';
  }
  return resolved;
}

String? _nullableString(dynamic value) {
  final resolved = _asString(value);
  if (resolved.isEmpty) {
    return null;
  }
  return resolved;
}
