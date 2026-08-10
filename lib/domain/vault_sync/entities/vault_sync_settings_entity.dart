import 'package:pass_doc_manager/domain/vault_sync/entities/vault_sync_target_type.dart';

class VaultSyncSettingsEntity {
  const VaultSyncSettingsEntity({
    required this.targetType,
    required this.localFolderPath,
    required this.dropboxAccessToken,
    required this.dropboxDirectoryPath,
    required this.googleDriveAccessToken,
    required this.passphrase,
    required this.remoteCheckIntervalMinutes,
    required this.remoteCheckOnResume,
    required this.wifiOnlySyncChecks,
    required this.lowDataSyncMode,
    required this.autoRestoreRemoteChanges,
  });

  const VaultSyncSettingsEntity.defaults()
    : targetType = VaultSyncTargetType.none,
      localFolderPath = '',
      dropboxAccessToken = '',
      dropboxDirectoryPath = '/vaultmark_sync',
      googleDriveAccessToken = '',
      passphrase = '',
      remoteCheckIntervalMinutes = 30,
      remoteCheckOnResume = true,
      wifiOnlySyncChecks = true,
      lowDataSyncMode = true,
      autoRestoreRemoteChanges = false;

  final VaultSyncTargetType targetType;
  final String localFolderPath;
  final String dropboxAccessToken;
  final String dropboxDirectoryPath;
  final String googleDriveAccessToken;
  final String passphrase;
  final int remoteCheckIntervalMinutes;
  final bool remoteCheckOnResume;
  final bool wifiOnlySyncChecks;
  final bool lowDataSyncMode;
  final bool autoRestoreRemoteChanges;

  VaultSyncSettingsEntity copyWith({
    VaultSyncTargetType? targetType,
    String? localFolderPath,
    String? dropboxAccessToken,
    String? dropboxDirectoryPath,
    String? googleDriveAccessToken,
    String? passphrase,
    int? remoteCheckIntervalMinutes,
    bool? remoteCheckOnResume,
    bool? wifiOnlySyncChecks,
    bool? lowDataSyncMode,
    bool? autoRestoreRemoteChanges,
  }) {
    return VaultSyncSettingsEntity(
      targetType: targetType ?? this.targetType,
      localFolderPath: localFolderPath ?? this.localFolderPath,
      dropboxAccessToken: dropboxAccessToken ?? this.dropboxAccessToken,
      dropboxDirectoryPath: dropboxDirectoryPath ?? this.dropboxDirectoryPath,
      googleDriveAccessToken:
          googleDriveAccessToken ?? this.googleDriveAccessToken,
      passphrase: passphrase ?? this.passphrase,
      remoteCheckIntervalMinutes:
          remoteCheckIntervalMinutes ?? this.remoteCheckIntervalMinutes,
      remoteCheckOnResume: remoteCheckOnResume ?? this.remoteCheckOnResume,
      wifiOnlySyncChecks: wifiOnlySyncChecks ?? this.wifiOnlySyncChecks,
      lowDataSyncMode: lowDataSyncMode ?? this.lowDataSyncMode,
      autoRestoreRemoteChanges:
          autoRestoreRemoteChanges ?? this.autoRestoreRemoteChanges,
    );
  }
}
