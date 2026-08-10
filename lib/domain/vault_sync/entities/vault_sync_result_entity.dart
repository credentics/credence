class VaultSyncResultEntity {
  const VaultSyncResultEntity({
    required this.success,
    required this.message,
    required this.uploaded,
    required this.downloaded,
    required this.conflictDetected,
  });

  final bool success;
  final String message;
  final bool uploaded;
  final bool downloaded;
  final bool conflictDetected;
}
