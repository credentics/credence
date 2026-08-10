class VaultSyncBlobRefEntity {
  const VaultSyncBlobRefEntity({
    required this.hash,
    required this.sizeBytes,
    required this.readablePath,
    this.originalName,
  });

  factory VaultSyncBlobRefEntity.fromMap(Map<String, dynamic> map) {
    return VaultSyncBlobRefEntity(
      hash: '${map['hash'] ?? ''}'.trim(),
      sizeBytes: _asInt(map['size_bytes'] ?? map['sizeBytes']),
      readablePath: '${map['readable_path'] ?? map['readablePath'] ?? ''}'
          .trim(),
      originalName: _nullableString(
        map['original_name'] ?? map['originalName'],
      ),
    );
  }

  final String hash;
  final int sizeBytes;
  final String readablePath;
  final String? originalName;

  Map<String, dynamic> toMap() {
    return {
      'hash': hash,
      'size_bytes': sizeBytes,
      'readable_path': readablePath,
      'original_name': originalName,
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
