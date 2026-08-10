import 'dart:convert';

class VaultSyncManifestDto {
  const VaultSyncManifestDto({
    required this.version,
    required this.revision,
    required this.deviceId,
    required this.updatedAtIso,
    required this.payloadChecksum,
    required this.bundleId,
  });

  final int version;
  final int revision;
  final String deviceId;
  final String updatedAtIso;
  final String payloadChecksum;
  final String bundleId;

  Map<String, dynamic> toMap() {
    return {
      'version': version,
      'revision': revision,
      'deviceId': deviceId,
      'updatedAtIso': updatedAtIso,
      'payloadChecksum': payloadChecksum,
      'bundleId': bundleId,
    };
  }

  String toJsonText() => jsonEncode(toMap());

  factory VaultSyncManifestDto.fromMap(Map<String, dynamic> map) {
    return VaultSyncManifestDto(
      version: map['version'] as int? ?? 1,
      revision: map['revision'] as int? ?? 0,
      deviceId: map['deviceId'] as String? ?? '',
      updatedAtIso: map['updatedAtIso'] as String? ?? '',
      payloadChecksum: map['payloadChecksum'] as String? ?? '',
      bundleId: map['bundleId'] as String? ?? '',
    );
  }

  factory VaultSyncManifestDto.fromJsonText(String source) {
    return VaultSyncManifestDto.fromMap(
      jsonDecode(source) as Map<String, dynamic>,
    );
  }
}
