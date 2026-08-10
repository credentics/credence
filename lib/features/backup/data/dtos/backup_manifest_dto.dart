import 'package:pass_doc_manager/features/backup/domain/entities/backup_manifest.dart';
import 'package:pass_doc_manager/features/backup/domain/entities/backup_type.dart';

class BackupManifestDto {
  const BackupManifestDto({
    required this.manifestVersion,
    required this.backupId,
    required this.backupTypeKey,
    this.parentBackupId,
    required this.deviceId,
    required this.deviceName,
    required this.appVersion,
    required this.schemaVersion,
    required this.createdAtIso,
    required this.journalFromSequence,
    required this.journalToSequence,
    required this.entityCount,
    required this.fileCount,
    required this.tombstoneCount,
    required this.archiveSizeBytes,
    required this.archiveHash,
    this.encryptionAlgorithm,
    this.kdf,
    this.kdfMemory,
    this.kdfIterations,
    this.kdfParallelism,
    this.salt,
    this.nonce,
    required this.chainDepth,
    this.isEmergencyBackup = false,
    this.remoteFileName,
    this.warningMessage,
  });

  factory BackupManifestDto.fromMap(Map<String, dynamic> map) {
    return BackupManifestDto(
      manifestVersion: _asInt(map['manifest_version']),
      backupId: _asString(map['backup_id']),
      backupTypeKey: _asString(map['backup_type']),
      parentBackupId: _nullableString(map['parent_backup_id']),
      deviceId: _asString(map['device_id']),
      deviceName: _asString(map['device_name']),
      appVersion: _asString(map['app_version']),
      schemaVersion: _asInt(map['schema_version']),
      createdAtIso: _asString(map['created_at_iso']),
      journalFromSequence: _asInt(map['journal_from_sequence']),
      journalToSequence: _asInt(map['journal_to_sequence']),
      entityCount: _asInt(map['entity_count']),
      fileCount: _asInt(map['file_count']),
      tombstoneCount: _asInt(map['tombstone_count']),
      archiveSizeBytes: _asInt(map['archive_size_bytes']),
      archiveHash: _asString(map['archive_hash']),
      encryptionAlgorithm: _nullableString(map['encryption_algorithm']),
      kdf: _nullableString(map['kdf']),
      kdfMemory: _nullableInt(map['kdf_memory']),
      kdfIterations: _nullableInt(map['kdf_iterations']),
      kdfParallelism: _nullableInt(map['kdf_parallelism']),
      salt: _nullableString(map['salt']),
      nonce: _nullableString(map['nonce']),
      chainDepth: _asInt(map['chain_depth']),
      isEmergencyBackup: map['is_emergency_backup'] == true,
      remoteFileName: _nullableString(map['remote_file_name']),
      warningMessage: _nullableString(map['warning_message']),
    );
  }

  factory BackupManifestDto.fromEntity(BackupManifest entity) {
    return BackupManifestDto(
      manifestVersion: entity.manifestVersion,
      backupId: entity.backupId,
      backupTypeKey: entity.backupType.key,
      parentBackupId: entity.parentBackupId,
      deviceId: entity.deviceId,
      deviceName: entity.deviceName,
      appVersion: entity.appVersion,
      schemaVersion: entity.schemaVersion,
      createdAtIso: entity.createdAt.toIso8601String(),
      journalFromSequence: entity.journalFromSequence,
      journalToSequence: entity.journalToSequence,
      entityCount: entity.entityCount,
      fileCount: entity.fileCount,
      tombstoneCount: entity.tombstoneCount,
      archiveSizeBytes: entity.archiveSizeBytes,
      archiveHash: entity.archiveHash,
      encryptionAlgorithm: entity.encryptionAlgorithm,
      kdf: entity.kdf,
      kdfMemory: entity.kdfMemory,
      kdfIterations: entity.kdfIterations,
      kdfParallelism: entity.kdfParallelism,
      salt: entity.salt,
      nonce: entity.nonce,
      chainDepth: entity.chainDepth,
      isEmergencyBackup: entity.isEmergencyBackup,
      remoteFileName: entity.remoteFileName,
      warningMessage: entity.warningMessage,
    );
  }

  final int manifestVersion;
  final String backupId;
  final String backupTypeKey;
  final String? parentBackupId;
  final String deviceId;
  final String deviceName;
  final String appVersion;
  final int schemaVersion;
  final String createdAtIso;
  final int journalFromSequence;
  final int journalToSequence;
  final int entityCount;
  final int fileCount;
  final int tombstoneCount;
  final int archiveSizeBytes;
  final String archiveHash;
  final String? encryptionAlgorithm;
  final String? kdf;
  final int? kdfMemory;
  final int? kdfIterations;
  final int? kdfParallelism;
  final String? salt;
  final String? nonce;
  final int chainDepth;
  final bool isEmergencyBackup;
  final String? remoteFileName;
  final String? warningMessage;

  Map<String, dynamic> toMap() {
    return {
      'manifest_version': manifestVersion,
      'backup_id': backupId,
      'backup_type': backupTypeKey,
      'parent_backup_id': parentBackupId,
      'device_id': deviceId,
      'device_name': deviceName,
      'app_version': appVersion,
      'schema_version': schemaVersion,
      'created_at_iso': createdAtIso,
      'journal_from_sequence': journalFromSequence,
      'journal_to_sequence': journalToSequence,
      'entity_count': entityCount,
      'file_count': fileCount,
      'tombstone_count': tombstoneCount,
      'archive_size_bytes': archiveSizeBytes,
      'archive_hash': archiveHash,
      'encryption_algorithm': encryptionAlgorithm,
      'kdf': kdf,
      'kdf_memory': kdfMemory,
      'kdf_iterations': kdfIterations,
      'kdf_parallelism': kdfParallelism,
      'salt': salt,
      'nonce': nonce,
      'chain_depth': chainDepth,
      'is_emergency_backup': isEmergencyBackup,
      'remote_file_name': remoteFileName,
      'warning_message': warningMessage,
    };
  }

  BackupManifest toEntity() {
    return BackupManifest(
      manifestVersion: manifestVersion,
      backupId: backupId,
      backupType: BackupTypeX.fromKey(backupTypeKey),
      parentBackupId: parentBackupId,
      deviceId: deviceId,
      deviceName: deviceName,
      appVersion: appVersion,
      schemaVersion: schemaVersion,
      createdAt: DateTime.parse(createdAtIso),
      journalFromSequence: journalFromSequence,
      journalToSequence: journalToSequence,
      entityCount: entityCount,
      fileCount: fileCount,
      tombstoneCount: tombstoneCount,
      archiveSizeBytes: archiveSizeBytes,
      archiveHash: archiveHash,
      encryptionAlgorithm: encryptionAlgorithm,
      kdf: kdf,
      kdfMemory: kdfMemory,
      kdfIterations: kdfIterations,
      kdfParallelism: kdfParallelism,
      salt: salt,
      nonce: nonce,
      chainDepth: chainDepth,
      isEmergencyBackup: isEmergencyBackup,
      remoteFileName: remoteFileName,
      warningMessage: warningMessage,
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
