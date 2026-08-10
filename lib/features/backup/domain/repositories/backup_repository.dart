import 'package:pass_doc_manager/features/backup/domain/entities/backup_chain.dart';
import 'package:pass_doc_manager/features/backup/domain/entities/backup_manifest.dart';
import 'package:pass_doc_manager/features/backup/domain/entities/backup_operation_progress.dart';
import 'package:pass_doc_manager/features/backup/domain/entities/device_identity.dart';

abstract class BackupRepository {
  /// Creates a backup (full, delta, or compacted based on chain state).
  Future<BackupManifest> createBackup({
    required String passphrase,
    BackupOperationProgressCallback? onProgress,
  });

  /// Restores app state from a specific backup (replays chain if needed).
  Future<void> restoreFromBackup({
    required String backupId,
    required String passphrase,
    BackupOperationProgressCallback? onProgress,
  });

  /// Lists all known backups (local + remote).
  Future<List<BackupManifest>> listBackups();

  /// Deletes a specific backup (local + remote).
  Future<void> deleteBackup(String backupId);

  /// Returns the current active chain.
  Future<BackupChain> getActiveChain();

  /// Validates the current chain integrity.
  Future<ChainValidationResult> validateChain();

  /// Uploads any pending local backups to the remote provider.
  /// [onProgress] is called with (uploadedCount, totalCount, currentFileName)
  /// for each file uploaded, allowing the UI to display progress.
  Future<void> uploadPendingBackups({
    required String accessToken,
    void Function(int uploaded, int total, String fileName)? onProgress,
  });

  /// Downloads a specific backup from the remote provider.
  Future<void> downloadBackup({
    required String backupId,
    required String accessToken,
  });

  /// Restores from raw encrypted bytes downloaded from cloud.
  Future<void> restoreFromCloudDownload({
    required List<int> encryptedBytes,
    required String passphrase,
    required Map<String, dynamic> manifestMap,
    BackupOperationProgressCallback? onProgress,
  });

  /// Returns the current device identity.
  Future<DeviceIdentity> getDeviceIdentity();
}
