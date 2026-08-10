import 'dart:convert';

import 'package:pass_doc_manager/domain/vault_sync/entities/vault_sync_blob_ref_entity.dart';
import 'package:pass_doc_manager/domain/vault_sync/entities/vault_sync_tombstone_entity.dart';

class VaultSyncOperationEntity {
  const VaultSyncOperationEntity({
    required this.opId,
    required this.deviceId,
    required this.sequence,
    required this.entityType,
    required this.entityId,
    required this.operation,
    required this.baseHash,
    required this.contentHash,
    required this.createdAtIso,
    required this.payload,
    this.blobs = const [],
    this.tombstone,
    this.uploaded = false,
  });

  factory VaultSyncOperationEntity.fromMap(Map<String, dynamic> map) {
    final blobRaw = map['blobs'];
    final tombstoneRaw = map['tombstone'];
    return VaultSyncOperationEntity(
      opId: '${map['op_id'] ?? map['opId'] ?? ''}'.trim(),
      deviceId: '${map['device_id'] ?? map['deviceId'] ?? ''}'.trim(),
      sequence: _asInt(map['sequence']),
      entityType: '${map['entity_type'] ?? map['entityType'] ?? ''}'.trim(),
      entityId: '${map['entity_id'] ?? map['entityId'] ?? ''}'.trim(),
      operation: '${map['operation'] ?? ''}'.trim(),
      baseHash: '${map['base_hash'] ?? map['baseHash'] ?? ''}'.trim(),
      contentHash: '${map['content_hash'] ?? map['contentHash'] ?? ''}'.trim(),
      createdAtIso: '${map['created_at_iso'] ?? map['createdAtIso'] ?? ''}'
          .trim(),
      payload: map['payload'] is Map
          ? Map<String, dynamic>.from(map['payload'] as Map)
          : const <String, dynamic>{},
      blobs: blobRaw is List
          ? blobRaw
                .whereType<Map>()
                .map(
                  (item) => VaultSyncBlobRefEntity.fromMap(
                    Map<String, dynamic>.from(item),
                  ),
                )
                .toList(growable: false)
          : const <VaultSyncBlobRefEntity>[],
      tombstone: tombstoneRaw is Map
          ? VaultSyncTombstoneEntity.fromMap(
              Map<String, dynamic>.from(tombstoneRaw),
            )
          : null,
      uploaded: map['uploaded'] == true,
    );
  }

  factory VaultSyncOperationEntity.fromJsonText(String source) {
    final decoded = jsonDecode(source);
    if (decoded is! Map) {
      throw const FormatException('Sync operation must be a JSON object.');
    }
    return VaultSyncOperationEntity.fromMap(Map<String, dynamic>.from(decoded));
  }

  final String opId;
  final String deviceId;
  final int sequence;
  final String entityType;
  final String entityId;
  final String operation;
  final String baseHash;
  final String contentHash;
  final String createdAtIso;
  final Map<String, dynamic> payload;
  final List<VaultSyncBlobRefEntity> blobs;
  final VaultSyncTombstoneEntity? tombstone;
  final bool uploaded;

  VaultSyncOperationEntity copyWith({bool? uploaded}) {
    return VaultSyncOperationEntity(
      opId: opId,
      deviceId: deviceId,
      sequence: sequence,
      entityType: entityType,
      entityId: entityId,
      operation: operation,
      baseHash: baseHash,
      contentHash: contentHash,
      createdAtIso: createdAtIso,
      payload: payload,
      blobs: blobs,
      tombstone: tombstone,
      uploaded: uploaded ?? this.uploaded,
    );
  }

  Map<String, dynamic> toMap({bool includeLocalState = true}) {
    return {
      'op_id': opId,
      'device_id': deviceId,
      'sequence': sequence,
      'entity_type': entityType,
      'entity_id': entityId,
      'operation': operation,
      'base_hash': baseHash,
      'content_hash': contentHash,
      'created_at_iso': createdAtIso,
      'payload': payload,
      'blobs': blobs.map((blob) => blob.toMap()).toList(growable: false),
      'tombstone': tombstone?.toMap(),
      if (includeLocalState) 'uploaded': uploaded,
    };
  }

  String toJsonText({bool includeLocalState = false}) {
    return const JsonEncoder.withIndent(
      '  ',
    ).convert(toMap(includeLocalState: includeLocalState));
  }
}

int _asInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse('$value') ?? 0;
}
