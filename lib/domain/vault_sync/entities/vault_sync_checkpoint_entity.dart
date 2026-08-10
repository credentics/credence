class VaultSyncCheckpointEntity {
  const VaultSyncCheckpointEntity({
    required this.deviceId,
    required this.lastSequence,
    required this.lastSyncedAtIso,
    this.remoteHeadRev,
  });

  factory VaultSyncCheckpointEntity.fromMap(Map<String, dynamic> map) {
    return VaultSyncCheckpointEntity(
      deviceId: '${map['device_id'] ?? map['deviceId'] ?? ''}'.trim(),
      lastSequence: _asInt(map['last_sequence'] ?? map['lastSequence']),
      lastSyncedAtIso:
          '${map['last_synced_at_iso'] ?? map['lastSyncedAtIso'] ?? ''}'.trim(),
      remoteHeadRev: _nullableString(
        map['remote_head_rev'] ?? map['remoteHeadRev'],
      ),
    );
  }

  final String deviceId;
  final int lastSequence;
  final String lastSyncedAtIso;
  final String? remoteHeadRev;

  Map<String, dynamic> toMap() {
    return {
      'device_id': deviceId,
      'last_sequence': lastSequence,
      'last_synced_at_iso': lastSyncedAtIso,
      'remote_head_rev': remoteHeadRev,
    };
  }
}

int _asInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse('$value') ?? 0;
}

String? _nullableString(dynamic value) {
  final resolved = '${value ?? ''}'.trim();
  return resolved.isEmpty || resolved.toLowerCase() == 'null' ? null : resolved;
}
