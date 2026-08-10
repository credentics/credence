import 'package:pass_doc_manager/features/backup/domain/entities/backup_manifest.dart';

class BackupChain {
  const BackupChain({
    required this.chainId,
    required this.baseBackupId,
    required this.headBackupId,
    required this.depth,
    required this.deviceId,
    required this.backups,
  });

  final String chainId;
  final String baseBackupId;
  final String headBackupId;
  final int depth;
  final String deviceId;
  final List<BackupManifest> backups;

  bool get needsCompaction => depth >= 10;
  bool get isEmpty => backups.isEmpty;
  BackupManifest? get head => backups.isNotEmpty ? backups.last : null;
  BackupManifest? get base => backups.isNotEmpty ? backups.first : null;
}

enum ChainValidationStatus {
  valid,
  empty,
  noBase,
  broken,
  orphaned,
}

class ChainValidationResult {
  const ChainValidationResult({
    required this.status,
    this.brokenAtIndex,
    this.message,
  });

  final ChainValidationStatus status;
  final int? brokenAtIndex;
  final String? message;

  bool get isValid => status == ChainValidationStatus.valid;
}
