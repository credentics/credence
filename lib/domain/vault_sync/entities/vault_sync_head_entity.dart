import 'dart:convert';

class VaultSyncHeadEntity {
  const VaultSyncHeadEntity({
    required this.revision,
    required this.deviceId,
    required this.manifestHash,
    required this.generatedAtIso,
    required this.provider,
    required this.fileCount,
    required this.directoryCount,
  });

  factory VaultSyncHeadEntity.fromMap(Map<String, dynamic> map) {
    return VaultSyncHeadEntity(
      revision: _asInt(map['revision']),
      deviceId: '${map['deviceId'] ?? map['device_id'] ?? ''}'.trim(),
      manifestHash: '${map['manifestHash'] ?? map['manifest_hash'] ?? ''}'
          .trim(),
      generatedAtIso:
          '${map['generatedAtIso'] ?? map['generated_at_iso'] ?? ''}'.trim(),
      provider: '${map['provider'] ?? ''}'.trim(),
      fileCount: _asInt(map['fileCount'] ?? map['file_count']),
      directoryCount: _asInt(map['directoryCount'] ?? map['directory_count']),
    );
  }

  factory VaultSyncHeadEntity.fromJsonText(String source) {
    final decoded = jsonDecode(source);
    if (decoded is! Map) {
      throw const FormatException('Sync head must be a JSON object.');
    }
    return VaultSyncHeadEntity.fromMap(Map<String, dynamic>.from(decoded));
  }

  factory VaultSyncHeadEntity.fromManifestMap({
    required Map<String, dynamic> manifest,
    required String provider,
    required String manifestHash,
  }) {
    return VaultSyncHeadEntity(
      revision: _asInt(manifest['revision']),
      deviceId: '${manifest['device_id'] ?? ''}'.trim(),
      manifestHash: manifestHash,
      generatedAtIso: '${manifest['generated_at_iso'] ?? ''}'.trim(),
      provider: provider,
      fileCount: manifest['files'] is List
          ? (manifest['files'] as List).length
          : 0,
      directoryCount: manifest['directories'] is List
          ? (manifest['directories'] as List).length
          : 0,
    );
  }

  final int revision;
  final String deviceId;
  final String manifestHash;
  final String generatedAtIso;
  final String provider;
  final int fileCount;
  final int directoryCount;

  bool get isValid => revision > 0 && manifestHash.trim().isNotEmpty;

  Map<String, dynamic> toMap() {
    return {
      'revision': revision,
      'deviceId': deviceId,
      'manifestHash': manifestHash,
      'generatedAtIso': generatedAtIso,
      'provider': provider,
      'fileCount': fileCount,
      'directoryCount': directoryCount,
    };
  }

  String toJsonText() => const JsonEncoder.withIndent('  ').convert(toMap());

  static int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse('$value') ?? 0;
  }
}
