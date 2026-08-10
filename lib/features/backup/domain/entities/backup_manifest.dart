import 'package:pass_doc_manager/features/backup/domain/entities/backup_type.dart';

class BackupManifest {
  const BackupManifest({
    required this.manifestVersion,
    required this.backupId,
    required this.backupType,
    this.parentBackupId,
    required this.deviceId,
    required this.deviceName,
    required this.appVersion,
    required this.schemaVersion,
    required this.createdAt,
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

  final int manifestVersion;
  final String backupId;
  final BackupType backupType;
  final String? parentBackupId;
  final String deviceId;
  final String deviceName;
  final String appVersion;
  final int schemaVersion;
  final DateTime createdAt;
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

  bool get isEncrypted => encryptionAlgorithm != null;
  bool get isFull =>
      backupType == BackupType.full || backupType == BackupType.compacted;
}
