import 'package:pass_doc_manager/data/vault_sync/dtos/vault_sync_prefs_dto.dart';
import 'package:pass_doc_manager/domain/vault_sync/entities/vault_sync_result_entity.dart';
import 'package:pass_doc_manager/domain/vault_sync/entities/vault_sync_settings_entity.dart';
import 'package:pass_doc_manager/domain/vault_sync/entities/vault_sync_status_entity.dart';
import 'package:pass_doc_manager/domain/vault_sync/entities/vault_sync_target_type.dart';

extension VaultSyncTargetMapper on String {
  VaultSyncTargetType toTargetType() {
    switch (trim().toLowerCase()) {
      case 'local_folder':
        return VaultSyncTargetType.localFolder;
      case 'dropbox_cloud':
        return VaultSyncTargetType.dropboxCloud;
      case 'google_drive_cloud':
        return VaultSyncTargetType.googleDriveCloud;
      case 'none':
      default:
        return VaultSyncTargetType.none;
    }
  }
}

extension VaultSyncTargetEntityMapper on VaultSyncTargetType {
  String toStorageValue() {
    switch (this) {
      case VaultSyncTargetType.localFolder:
        return 'local_folder';
      case VaultSyncTargetType.dropboxCloud:
        return 'dropbox_cloud';
      case VaultSyncTargetType.googleDriveCloud:
        return 'google_drive_cloud';
      case VaultSyncTargetType.none:
        return 'none';
    }
  }
}

extension VaultSyncPrefsDtoMapper on VaultSyncPrefsDto {
  VaultSyncSettingsEntity toSettingsEntity() {
    return VaultSyncSettingsEntity(
      targetType: targetType.toTargetType(),
      localFolderPath: localFolderPath,
      dropboxAccessToken: dropboxAccessToken,
      dropboxDirectoryPath: dropboxDirectoryPath,
      googleDriveAccessToken: googleDriveAccessToken,
      passphrase: passphrase,
      remoteCheckIntervalMinutes: remoteCheckIntervalMinutes,
      remoteCheckOnResume: remoteCheckOnResume,
      wifiOnlySyncChecks: wifiOnlySyncChecks,
      lowDataSyncMode: lowDataSyncMode,
      autoRestoreRemoteChanges: autoRestoreRemoteChanges,
    );
  }

  VaultSyncStatusEntity toStatusEntity() {
    return VaultSyncStatusEntity(
      lastSyncedAtIso: lastSyncedAtIso,
      lastRunSuccessful: lastRunSuccessful,
      lastMessage: lastMessage,
      lastObservedRemoteRevision: lastObservedRemoteRevision,
      lastRemoteCheckedAtIso: lastRemoteCheckedAtIso,
      lastRemoteRevision: lastRemoteRevision,
      lastRemoteChecksum: lastRemoteChecksum,
      lastRemoteDeviceId: lastRemoteDeviceId,
      syncBackoffUntilIso: syncBackoffUntilIso,
    );
  }
}

extension VaultSyncSettingsEntityMapper on VaultSyncSettingsEntity {
  VaultSyncPrefsDto mergedInto(VaultSyncPrefsDto base) {
    final nextDropboxAccessToken = dropboxAccessToken.trim();
    final dropboxAccessTokenChanged =
        nextDropboxAccessToken != base.dropboxAccessToken.trim();
    return base.copyWith(
      targetType: targetType.toStorageValue(),
      localFolderPath: localFolderPath.trim(),
      dropboxAccessToken: nextDropboxAccessToken,
      dropboxRefreshToken: dropboxAccessTokenChanged
          ? ''
          : base.dropboxRefreshToken,
      dropboxAccessTokenExpiresAtIso: dropboxAccessTokenChanged
          ? ''
          : base.dropboxAccessTokenExpiresAtIso,
      dropboxDirectoryPath: dropboxDirectoryPath.trim(),
      googleDriveAccessToken: googleDriveAccessToken.trim(),
      passphrase: passphrase,
      remoteCheckIntervalMinutes: remoteCheckIntervalMinutes,
      remoteCheckOnResume: remoteCheckOnResume,
      wifiOnlySyncChecks: wifiOnlySyncChecks,
      lowDataSyncMode: lowDataSyncMode,
      autoRestoreRemoteChanges: autoRestoreRemoteChanges,
    );
  }
}

VaultSyncResultEntity buildSyncResult({
  required bool success,
  required String message,
  required bool uploaded,
  required bool downloaded,
  required bool conflictDetected,
}) {
  return VaultSyncResultEntity(
    success: success,
    message: message,
    uploaded: uploaded,
    downloaded: downloaded,
    conflictDetected: conflictDetected,
  );
}
