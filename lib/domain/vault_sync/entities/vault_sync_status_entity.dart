class VaultSyncStatusEntity {
  const VaultSyncStatusEntity({
    required this.lastSyncedAtIso,
    required this.lastRunSuccessful,
    required this.lastMessage,
    required this.lastObservedRemoteRevision,
    required this.lastRemoteCheckedAtIso,
    required this.lastRemoteRevision,
    required this.lastRemoteChecksum,
    required this.lastRemoteDeviceId,
    required this.syncBackoffUntilIso,
  });

  const VaultSyncStatusEntity.initial()
    : lastSyncedAtIso = null,
      lastRunSuccessful = true,
      lastMessage = 'Sync has not run yet.',
      lastObservedRemoteRevision = 0,
      lastRemoteCheckedAtIso = null,
      lastRemoteRevision = 0,
      lastRemoteChecksum = '',
      lastRemoteDeviceId = '',
      syncBackoffUntilIso = null;

  final String? lastSyncedAtIso;
  final bool lastRunSuccessful;
  final String lastMessage;
  final int lastObservedRemoteRevision;
  final String? lastRemoteCheckedAtIso;
  final int lastRemoteRevision;
  final String lastRemoteChecksum;
  final String lastRemoteDeviceId;
  final String? syncBackoffUntilIso;
}
