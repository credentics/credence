import 'package:pass_doc_manager/features/backup/domain/entities/journal_entry.dart';

class BackupJournalEntryDto {
  const BackupJournalEntryDto({
    required this.journalId,
    required this.sequenceNumber,
    required this.deviceId,
    required this.timestampIso,
    required this.operationKey,
    required this.entityId,
    required this.entityType,
    this.previousRevision,
    this.newRevision,
    this.previousContentHash,
    this.newContentHash,
    this.affectedFileIds = const [],
    this.metadata = const {},
  });

  factory BackupJournalEntryDto.fromMap(Map<String, dynamic> map) {
    final affectedRaw = map['affected_file_ids'];
    final metadataRaw = map['metadata'];

    return BackupJournalEntryDto(
      journalId: _asString(map['journal_id']),
      sequenceNumber: _asInt(map['sequence_number']),
      deviceId: _asString(map['device_id']),
      timestampIso: _asString(map['timestamp']),
      operationKey: _asString(map['operation']),
      entityId: _asString(map['entity_id']),
      entityType: _asString(map['entity_type']),
      previousRevision: _nullableInt(map['previous_revision']),
      newRevision: _nullableInt(map['new_revision']),
      previousContentHash: _nullableString(map['previous_content_hash']),
      newContentHash: _nullableString(map['new_content_hash']),
      affectedFileIds: affectedRaw is List
          ? affectedRaw
                .map((value) => '$value'.trim())
                .where((v) => v.isNotEmpty)
                .toList(growable: false)
          : const <String>[],
      metadata: metadataRaw is Map
          ? Map<String, String>.fromEntries(
              metadataRaw.entries.map(
                (entry) => MapEntry('${entry.key}', '${entry.value}'),
              ),
            )
          : const <String, String>{},
    );
  }

  factory BackupJournalEntryDto.fromEntity(BackupJournalEntry entity) {
    return BackupJournalEntryDto(
      journalId: entity.journalId,
      sequenceNumber: entity.sequenceNumber,
      deviceId: entity.deviceId,
      timestampIso: entity.timestamp.toIso8601String(),
      operationKey: entity.operation.key,
      entityId: entity.entityId,
      entityType: entity.entityType,
      previousRevision: entity.previousRevision,
      newRevision: entity.newRevision,
      previousContentHash: entity.previousContentHash,
      newContentHash: entity.newContentHash,
      affectedFileIds: entity.affectedFileIds,
      metadata: entity.metadata,
    );
  }

  final String journalId;
  final int sequenceNumber;
  final String deviceId;
  final String timestampIso;
  final String operationKey;
  final String entityId;
  final String entityType;
  final int? previousRevision;
  final int? newRevision;
  final String? previousContentHash;
  final String? newContentHash;
  final List<String> affectedFileIds;
  final Map<String, String> metadata;

  Map<String, dynamic> toMap() {
    return {
      'journal_id': journalId,
      'sequence_number': sequenceNumber,
      'device_id': deviceId,
      'timestamp': timestampIso,
      'operation': operationKey,
      'entity_id': entityId,
      'entity_type': entityType,
      'previous_revision': previousRevision,
      'new_revision': newRevision,
      'previous_content_hash': previousContentHash,
      'new_content_hash': newContentHash,
      'affected_file_ids': affectedFileIds,
      'metadata': metadata,
    };
  }

  BackupJournalEntry toEntity() {
    return BackupJournalEntry(
      journalId: journalId,
      sequenceNumber: sequenceNumber,
      deviceId: deviceId,
      timestamp: DateTime.parse(timestampIso),
      operation: JournalOperationX.fromKey(operationKey),
      entityId: entityId,
      entityType: entityType,
      previousRevision: previousRevision,
      newRevision: newRevision,
      previousContentHash: previousContentHash,
      newContentHash: newContentHash,
      affectedFileIds: affectedFileIds,
      metadata: metadata,
    );
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

int _asInt(dynamic value) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  return int.tryParse('$value') ?? 0;
}

int? _nullableInt(dynamic value) {
  if (value == null) {
    return null;
  }
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  return int.tryParse('$value');
}
