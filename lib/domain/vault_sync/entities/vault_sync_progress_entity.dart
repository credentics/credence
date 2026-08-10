typedef VaultSyncProgressCallback = void Function(VaultSyncProgressEntity);

class VaultSyncProgressEntity {
  const VaultSyncProgressEntity({
    required this.message,
    required this.detail,
    required this.progress,
    this.processedCount,
    this.totalCount,
    this.entityCount,
    this.fileCount,
  });

  final String message;
  final String detail;
  final double progress;
  final int? processedCount;
  final int? totalCount;
  final int? entityCount;
  final int? fileCount;
}
