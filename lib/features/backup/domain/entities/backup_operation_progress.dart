typedef BackupOperationProgressCallback =
    void Function(BackupOperationProgress progress);

class BackupOperationProgress {
  const BackupOperationProgress({
    required this.message,
    required this.detail,
    this.progress,
    this.processedCount,
    this.totalCount,
    this.entityCount,
    this.fileCount,
  });

  final String message;
  final String detail;
  final double? progress;
  final int? processedCount;
  final int? totalCount;
  final int? entityCount;
  final int? fileCount;
}
