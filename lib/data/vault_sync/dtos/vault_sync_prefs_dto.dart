import 'dart:convert';

class VaultSyncPrefsDto {
  const VaultSyncPrefsDto({
    required this.targetType,
    required this.localFolderPath,
    required this.dropboxAccessToken,
    required this.dropboxRefreshToken,
    required this.dropboxAccessTokenExpiresAtIso,
    required this.dropboxDirectoryPath,
    required this.passphrase,
    required this.deviceId,
    required this.lastSyncedAtIso,
    required this.lastRunSuccessful,
    required this.lastMessage,
    required this.lastObservedRemoteRevision,
    required this.lastUploadedChecksum,
    required this.googleDriveAccessToken,
    required this.selectedCloudProvider,
    required this.remoteCheckIntervalMinutes,
    required this.remoteCheckOnResume,
    required this.wifiOnlySyncChecks,
    required this.lowDataSyncMode,
    required this.autoRestoreRemoteChanges,
    required this.lastRemoteCheckedAtIso,
    required this.lastRemoteRevision,
    required this.lastRemoteChecksum,
    required this.lastRemoteDeviceId,
    required this.syncBackoffUntilIso,
    required this.syncBackoffFailureCount,
  });

  const VaultSyncPrefsDto.defaults()
    : targetType = 'none',
      localFolderPath = '',
      dropboxAccessToken = '',
      dropboxRefreshToken = '',
      dropboxAccessTokenExpiresAtIso = '',
      dropboxDirectoryPath = '/Credence',
      passphrase = '',
      deviceId = '',
      lastSyncedAtIso = null,
      lastRunSuccessful = true,
      lastMessage = 'Sync has not run yet.',
      lastObservedRemoteRevision = 0,
      lastUploadedChecksum = '',
      googleDriveAccessToken = '',
      selectedCloudProvider = 'dropbox',
      remoteCheckIntervalMinutes = 30,
      remoteCheckOnResume = true,
      wifiOnlySyncChecks = true,
      lowDataSyncMode = true,
      autoRestoreRemoteChanges = false,
      lastRemoteCheckedAtIso = null,
      lastRemoteRevision = 0,
      lastRemoteChecksum = '',
      lastRemoteDeviceId = '',
      syncBackoffUntilIso = null,
      syncBackoffFailureCount = 0;

  final String targetType;
  final String localFolderPath;
  final String dropboxAccessToken;
  final String dropboxRefreshToken;
  final String dropboxAccessTokenExpiresAtIso;
  final String dropboxDirectoryPath;
  final String passphrase;
  final String deviceId;
  final String? lastSyncedAtIso;
  final bool lastRunSuccessful;
  final String lastMessage;
  final int lastObservedRemoteRevision;
  final String lastUploadedChecksum;
  final String googleDriveAccessToken;
  final String selectedCloudProvider;
  final int remoteCheckIntervalMinutes;
  final bool remoteCheckOnResume;
  final bool wifiOnlySyncChecks;
  final bool lowDataSyncMode;
  final bool autoRestoreRemoteChanges;
  final String? lastRemoteCheckedAtIso;
  final int lastRemoteRevision;
  final String lastRemoteChecksum;
  final String lastRemoteDeviceId;
  final String? syncBackoffUntilIso;
  final int syncBackoffFailureCount;

  VaultSyncPrefsDto copyWith({
    String? targetType,
    String? localFolderPath,
    String? dropboxAccessToken,
    String? dropboxRefreshToken,
    String? dropboxAccessTokenExpiresAtIso,
    String? dropboxDirectoryPath,
    String? passphrase,
    String? deviceId,
    String? lastSyncedAtIso,
    bool? lastRunSuccessful,
    String? lastMessage,
    int? lastObservedRemoteRevision,
    String? lastUploadedChecksum,
    String? googleDriveAccessToken,
    String? selectedCloudProvider,
    int? remoteCheckIntervalMinutes,
    bool? remoteCheckOnResume,
    bool? wifiOnlySyncChecks,
    bool? lowDataSyncMode,
    bool? autoRestoreRemoteChanges,
    String? lastRemoteCheckedAtIso,
    int? lastRemoteRevision,
    String? lastRemoteChecksum,
    String? lastRemoteDeviceId,
    String? syncBackoffUntilIso,
    int? syncBackoffFailureCount,
    bool clearSyncBackoffUntilIso = false,
  }) {
    return VaultSyncPrefsDto(
      targetType: targetType ?? this.targetType,
      localFolderPath: localFolderPath ?? this.localFolderPath,
      dropboxAccessToken: dropboxAccessToken ?? this.dropboxAccessToken,
      dropboxRefreshToken: dropboxRefreshToken ?? this.dropboxRefreshToken,
      dropboxAccessTokenExpiresAtIso:
          dropboxAccessTokenExpiresAtIso ?? this.dropboxAccessTokenExpiresAtIso,
      dropboxDirectoryPath: dropboxDirectoryPath ?? this.dropboxDirectoryPath,
      passphrase: passphrase ?? this.passphrase,
      deviceId: deviceId ?? this.deviceId,
      lastSyncedAtIso: lastSyncedAtIso ?? this.lastSyncedAtIso,
      lastRunSuccessful: lastRunSuccessful ?? this.lastRunSuccessful,
      lastMessage: lastMessage ?? this.lastMessage,
      lastObservedRemoteRevision:
          lastObservedRemoteRevision ?? this.lastObservedRemoteRevision,
      lastUploadedChecksum: lastUploadedChecksum ?? this.lastUploadedChecksum,
      googleDriveAccessToken:
          googleDriveAccessToken ?? this.googleDriveAccessToken,
      selectedCloudProvider:
          selectedCloudProvider ?? this.selectedCloudProvider,
      remoteCheckIntervalMinutes:
          remoteCheckIntervalMinutes ?? this.remoteCheckIntervalMinutes,
      remoteCheckOnResume: remoteCheckOnResume ?? this.remoteCheckOnResume,
      wifiOnlySyncChecks: wifiOnlySyncChecks ?? this.wifiOnlySyncChecks,
      lowDataSyncMode: lowDataSyncMode ?? this.lowDataSyncMode,
      autoRestoreRemoteChanges:
          autoRestoreRemoteChanges ?? this.autoRestoreRemoteChanges,
      lastRemoteCheckedAtIso:
          lastRemoteCheckedAtIso ?? this.lastRemoteCheckedAtIso,
      lastRemoteRevision: lastRemoteRevision ?? this.lastRemoteRevision,
      lastRemoteChecksum: lastRemoteChecksum ?? this.lastRemoteChecksum,
      lastRemoteDeviceId: lastRemoteDeviceId ?? this.lastRemoteDeviceId,
      syncBackoffUntilIso: clearSyncBackoffUntilIso
          ? null
          : syncBackoffUntilIso ?? this.syncBackoffUntilIso,
      syncBackoffFailureCount:
          syncBackoffFailureCount ?? this.syncBackoffFailureCount,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'targetType': targetType,
      'localFolderPath': localFolderPath,
      'dropboxAccessToken': dropboxAccessToken,
      'dropboxRefreshToken': dropboxRefreshToken,
      'dropboxAccessTokenExpiresAtIso': dropboxAccessTokenExpiresAtIso,
      'dropboxDirectoryPath': dropboxDirectoryPath,
      'passphrase': passphrase,
      'deviceId': deviceId,
      'lastSyncedAtIso': lastSyncedAtIso,
      'lastRunSuccessful': lastRunSuccessful,
      'lastMessage': lastMessage,
      'lastObservedRemoteRevision': lastObservedRemoteRevision,
      'lastUploadedChecksum': lastUploadedChecksum,
      'googleDriveAccessToken': googleDriveAccessToken,
      'selectedCloudProvider': selectedCloudProvider,
      'remoteCheckIntervalMinutes': remoteCheckIntervalMinutes,
      'remoteCheckOnResume': remoteCheckOnResume,
      'wifiOnlySyncChecks': wifiOnlySyncChecks,
      'lowDataSyncMode': lowDataSyncMode,
      'autoRestoreRemoteChanges': autoRestoreRemoteChanges,
      'lastRemoteCheckedAtIso': lastRemoteCheckedAtIso,
      'lastRemoteRevision': lastRemoteRevision,
      'lastRemoteChecksum': lastRemoteChecksum,
      'lastRemoteDeviceId': lastRemoteDeviceId,
      'syncBackoffUntilIso': syncBackoffUntilIso,
      'syncBackoffFailureCount': syncBackoffFailureCount,
    };
  }

  String toJsonText() => jsonEncode(toMap());

  factory VaultSyncPrefsDto.fromMap(Map<String, dynamic> map) {
    return VaultSyncPrefsDto(
      targetType: (map['targetType'] as String?) ?? 'none',
      localFolderPath: (map['localFolderPath'] as String?) ?? '',
      dropboxAccessToken: (map['dropboxAccessToken'] as String?) ?? '',
      dropboxRefreshToken: (map['dropboxRefreshToken'] as String?) ?? '',
      dropboxAccessTokenExpiresAtIso:
          (map['dropboxAccessTokenExpiresAtIso'] as String?) ?? '',
      dropboxDirectoryPath:
          (map['dropboxDirectoryPath'] as String?) ?? '/Credence',
      passphrase: (map['passphrase'] as String?) ?? '',
      deviceId: (map['deviceId'] as String?) ?? '',
      lastSyncedAtIso: map['lastSyncedAtIso'] as String?,
      lastRunSuccessful: (map['lastRunSuccessful'] as bool?) ?? true,
      lastMessage: (map['lastMessage'] as String?) ?? 'Sync has not run yet.',
      lastObservedRemoteRevision:
          (map['lastObservedRemoteRevision'] as int?) ?? 0,
      lastUploadedChecksum: (map['lastUploadedChecksum'] as String?) ?? '',
      googleDriveAccessToken: (map['googleDriveAccessToken'] as String?) ?? '',
      selectedCloudProvider:
          (map['selectedCloudProvider'] as String?) ?? 'dropbox',
      remoteCheckIntervalMinutes: _asInt(
        map['remoteCheckIntervalMinutes'],
        fallback: 30,
      ),
      remoteCheckOnResume: (map['remoteCheckOnResume'] as bool?) ?? true,
      wifiOnlySyncChecks: (map['wifiOnlySyncChecks'] as bool?) ?? true,
      lowDataSyncMode: (map['lowDataSyncMode'] as bool?) ?? true,
      autoRestoreRemoteChanges:
          (map['autoRestoreRemoteChanges'] as bool?) ?? false,
      lastRemoteCheckedAtIso: map['lastRemoteCheckedAtIso'] as String?,
      lastRemoteRevision: _asInt(map['lastRemoteRevision']),
      lastRemoteChecksum: (map['lastRemoteChecksum'] as String?) ?? '',
      lastRemoteDeviceId: (map['lastRemoteDeviceId'] as String?) ?? '',
      syncBackoffUntilIso: map['syncBackoffUntilIso'] as String?,
      syncBackoffFailureCount: _asInt(map['syncBackoffFailureCount']),
    );
  }

  factory VaultSyncPrefsDto.fromJsonText(String source) {
    return VaultSyncPrefsDto.fromMap(
      jsonDecode(source) as Map<String, dynamic>,
    );
  }

  static int _asInt(dynamic value, {int fallback = 0}) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse('$value') ?? fallback;
  }
}
