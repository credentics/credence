class VaultSyncTombstoneEntity {
  const VaultSyncTombstoneEntity({
    required this.tombstoneId,
    required this.deviceId,
    required this.entityType,
    required this.entityId,
    required this.deletedAtIso,
    required this.baseHash,
    required this.retainUntilIso,
  });

  factory VaultSyncTombstoneEntity.fromMap(Map<String, dynamic> map) {
    return VaultSyncTombstoneEntity(
      tombstoneId: '${map['tombstone_id'] ?? map['tombstoneId'] ?? ''}'.trim(),
      deviceId: '${map['device_id'] ?? map['deviceId'] ?? ''}'.trim(),
      entityType: '${map['entity_type'] ?? map['entityType'] ?? ''}'.trim(),
      entityId: '${map['entity_id'] ?? map['entityId'] ?? ''}'.trim(),
      deletedAtIso: '${map['deleted_at_iso'] ?? map['deletedAtIso'] ?? ''}'
          .trim(),
      baseHash: '${map['base_hash'] ?? map['baseHash'] ?? ''}'.trim(),
      retainUntilIso:
          '${map['retain_until_iso'] ?? map['retainUntilIso'] ?? ''}'.trim(),
    );
  }

  final String tombstoneId;
  final String deviceId;
  final String entityType;
  final String entityId;
  final String deletedAtIso;
  final String baseHash;
  final String retainUntilIso;

  Map<String, dynamic> toMap() {
    return {
      'tombstone_id': tombstoneId,
      'device_id': deviceId,
      'entity_type': entityType,
      'entity_id': entityId,
      'deleted_at_iso': deletedAtIso,
      'base_hash': baseHash,
      'retain_until_iso': retainUntilIso,
    };
  }
}
