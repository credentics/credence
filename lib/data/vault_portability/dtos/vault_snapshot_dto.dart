import 'package:pass_doc_manager/data/vault_portability/dtos/vault_document_record_dto.dart';
import 'package:pass_doc_manager/data/vault_portability/dtos/vault_password_record_dto.dart';

class VaultSnapshotDto {
  const VaultSnapshotDto({
    required this.exportedAtIso,
    required this.documents,
    required this.passwords,
    this.collections = const <Map<String, dynamic>>[],
    this.bundles = const <Map<String, dynamic>>[],
    this.tasks = const <Map<String, dynamic>>[],
    this.profile,
  });

  final String exportedAtIso;
  final List<VaultDocumentRecordDto> documents;
  final List<VaultPasswordRecordDto> passwords;
  final List<Map<String, dynamic>> collections;

  /// Serialised `BundleRecordDto` maps. Optional — older snapshots may
  /// omit the key entirely; importers treat missing as empty.
  final List<Map<String, dynamic>> bundles;

  /// Serialised `TaskListRecordDto` maps (each carries its own `tasks[]`).
  final List<Map<String, dynamic>> tasks;

  final Map<String, dynamic>? profile;

  Map<String, dynamic> toMap() {
    return {
      'exportedAtIso': exportedAtIso,
      'documents': documents.map((item) => item.toMap()).toList(),
      'passwords': passwords.map((item) => item.toMap()).toList(),
      'collections': collections,
      if (bundles.isNotEmpty) 'bundles': bundles,
      if (tasks.isNotEmpty) 'tasks': tasks,
      if (profile != null) 'profile': profile,
    };
  }

  factory VaultSnapshotDto.fromMap(Map<String, dynamic> map) {
    final rawProfile = map['profile'];
    final profile = rawProfile is Map
        ? Map<String, dynamic>.from(rawProfile)
        : null;
    return VaultSnapshotDto(
      exportedAtIso: map['exportedAtIso'] as String,
      documents: (map['documents'] as List<dynamic>)
          .map(
            (item) =>
                VaultDocumentRecordDto.fromMap(item as Map<String, dynamic>),
          )
          .toList(),
      passwords: (map['passwords'] as List<dynamic>)
          .map(
            (item) =>
                VaultPasswordRecordDto.fromMap(item as Map<String, dynamic>),
          )
          .toList(),
      collections: _readMapList(map['collections']),
      bundles: _readMapList(map['bundles']),
      tasks: _readMapList(map['tasks']),
      profile: profile,
    );
  }

  static List<Map<String, dynamic>> _readMapList(dynamic raw) {
    if (raw is! List) return const <Map<String, dynamic>>[];
    return raw
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList(growable: false);
  }
}
