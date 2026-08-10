import 'package:pass_doc_manager/data/vault_sync/dtos/vault_sync_prefs_dto.dart';
import 'package:pass_doc_manager/features/backup/domain/entities/cloud_provider_type.dart';
import 'package:pass_doc_manager/features/backup/presentation/cubit/backup_state.dart';

enum BackupCoverageLevel { complete, partial, none }

class BackupCoverageSummary {
  const BackupCoverageSummary({
    required this.level,
    required this.title,
    required this.value,
    required this.detail,
    required this.hasLocalSnapshot,
    required this.hasCloudCopy,
    required this.hasCurrentCloudCopy,
    required this.hasLocalChangesPending,
    required this.hasRemoteChangesPending,
    required this.remoteCheckFailed,
  });

  final BackupCoverageLevel level;
  final String title;
  final String value;
  final String detail;
  final bool hasLocalSnapshot;
  final bool hasCloudCopy;
  final bool hasCurrentCloudCopy;
  final bool hasLocalChangesPending;
  final bool hasRemoteChangesPending;
  final bool remoteCheckFailed;
}

BackupCoverageSummary backupCoverageSummary({
  required BackupState state,
  required CloudProviderType provider,
  VaultSyncPrefsDto? prefs,
  String? currentContentChecksum,
  bool currentVaultChecked = false,
  bool currentContentBackedUp = false,
  bool remoteHasNewerCopy = false,
}) {
  final hasLocalSnapshot = state.lastBackup != null || state.backups.isNotEmpty;
  final remoteCheckFailed = state.remoteBackupCount < 0;
  final hasCloudCopy =
      !remoteCheckFailed &&
      (state.remoteBackupCount > 0 ||
          state.remoteStorageBytes > 0 ||
          state.remoteBackups.isNotEmpty);
  final isConnected = prefs == null || cloudProviderHasSession(provider, prefs);
  final providerLabel = provider.label;
  final currentChecksum = currentContentChecksum?.trim() ?? '';
  final lastRemoteChecksum = prefs?.lastRemoteChecksum.trim() ?? '';
  final lastAcceptedLocalChecksum = prefs?.lastUploadedChecksum.trim() ?? '';
  final hasCurrentCloudCopy =
      hasCloudCopy &&
      currentVaultChecked &&
      (currentContentBackedUp ||
          (currentChecksum.isNotEmpty &&
              (currentChecksum == lastRemoteChecksum ||
                  (currentChecksum == lastAcceptedLocalChecksum &&
                      !remoteHasNewerCopy))));
  final hasLocalChangesPending =
      currentVaultChecked &&
      currentChecksum.isNotEmpty &&
      hasCloudCopy &&
      !hasCurrentCloudCopy;

  if (hasLocalSnapshot && hasCurrentCloudCopy) {
    return BackupCoverageSummary(
      level: BackupCoverageLevel.complete,
      title: 'Everything backed up',
      value: 'Complete',
      detail: 'Local snapshot and $providerLabel copy are available.',
      hasLocalSnapshot: hasLocalSnapshot,
      hasCloudCopy: hasCloudCopy,
      hasCurrentCloudCopy: hasCurrentCloudCopy,
      hasLocalChangesPending: hasLocalChangesPending,
      hasRemoteChangesPending: false,
      remoteCheckFailed: remoteCheckFailed,
    );
  }

  if (hasLocalSnapshot ||
      hasCloudCopy ||
      remoteCheckFailed ||
      currentVaultChecked) {
    return BackupCoverageSummary(
      level: BackupCoverageLevel.partial,
      title: remoteHasNewerCopy
          ? 'Cloud changes available'
          : 'Partially backed up',
      value: 'Partial',
      detail: _partialDetail(
        provider: provider,
        hasLocalSnapshot: hasLocalSnapshot,
        hasCloudCopy: hasCloudCopy,
        hasCurrentCloudCopy: hasCurrentCloudCopy,
        hasLocalChangesPending: hasLocalChangesPending,
        hasRemoteChangesPending: remoteHasNewerCopy,
        remoteCheckFailed: remoteCheckFailed,
        isConnected: isConnected,
        currentVaultChecked: currentVaultChecked,
      ),
      hasLocalSnapshot: hasLocalSnapshot,
      hasCloudCopy: hasCloudCopy,
      hasCurrentCloudCopy: hasCurrentCloudCopy,
      hasLocalChangesPending: hasLocalChangesPending,
      hasRemoteChangesPending: remoteHasNewerCopy,
      remoteCheckFailed: remoteCheckFailed,
    );
  }

  return BackupCoverageSummary(
    level: BackupCoverageLevel.none,
    title: 'Nothing backed up',
    value: 'None',
    detail: isConnected
        ? 'Create a backup, then upload it to $providerLabel.'
        : 'Connect $providerLabel, then create a backup.',
    hasLocalSnapshot: hasLocalSnapshot,
    hasCloudCopy: hasCloudCopy,
    hasCurrentCloudCopy: hasCurrentCloudCopy,
    hasLocalChangesPending: hasLocalChangesPending,
    hasRemoteChangesPending: remoteHasNewerCopy,
    remoteCheckFailed: remoteCheckFailed,
  );
}

bool cloudProviderHasSession(
  CloudProviderType provider,
  VaultSyncPrefsDto prefs,
) {
  return switch (provider) {
    CloudProviderType.dropbox =>
      prefs.dropboxAccessToken.trim().isNotEmpty ||
          prefs.dropboxRefreshToken.trim().isNotEmpty,
    CloudProviderType.googleDrive =>
      prefs.googleDriveAccessToken.trim().isNotEmpty,
    CloudProviderType.iCloud => true,
  };
}

String _partialDetail({
  required CloudProviderType provider,
  required bool hasLocalSnapshot,
  required bool hasCloudCopy,
  required bool hasCurrentCloudCopy,
  required bool hasLocalChangesPending,
  required bool hasRemoteChangesPending,
  required bool remoteCheckFailed,
  required bool isConnected,
  required bool currentVaultChecked,
}) {
  final providerLabel = provider.label;
  if (remoteCheckFailed) {
    return hasLocalSnapshot
        ? 'Local snapshot exists. $providerLabel could not be verified.'
        : '$providerLabel could not be verified.';
  }
  if (!currentVaultChecked) {
    return 'Checking whether the latest vault changes reached $providerLabel.';
  }
  if (hasRemoteChangesPending) {
    return '$providerLabel has newer changes. Synchronize this device to import them.';
  }
  if (hasLocalChangesPending) {
    return 'New local changes have not been uploaded to $providerLabel yet.';
  }
  if (hasCloudCopy && !hasCurrentCloudCopy) {
    return '$providerLabel has an older copy. Upload again to include recent changes.';
  }
  if (hasLocalSnapshot && !hasCloudCopy) {
    if (!isConnected) {
      return 'Local snapshot exists. Connect $providerLabel to add cloud protection.';
    }
    if (provider == CloudProviderType.iCloud) {
      return 'Local snapshot exists. iCloud copy has not been created yet.';
    }
    return 'Local snapshot exists. Upload to $providerLabel to complete protection.';
  }
  if (!hasLocalSnapshot && hasCloudCopy) {
    return '$providerLabel has a copy. Create a local snapshot on this device.';
  }
  return 'Create a backup and verify the selected cloud provider.';
}
