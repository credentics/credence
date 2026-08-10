import 'package:pass_doc_manager/features/backup/domain/entities/backup_manifest.dart';

enum BackupViewStatus { initial, loading, ready, error }

class RemoteBackupInfo {
  const RemoteBackupInfo({
    required this.fileName,
    required this.sizeBytes,
    required this.modifiedAt,
  });

  final String fileName;
  final int sizeBytes;
  final DateTime modifiedAt;

  bool get isManifest => fileName.endsWith('.manifest.json');
  bool get isArchive => fileName.endsWith('.enc');
}

class BackupState {
  const BackupState({
    this.viewStatus = BackupViewStatus.initial,
    this.backups = const [],
    this.isCreating = false,
    this.isRestoring = false,
    this.isUploading = false,
    this.isLoadingRemote = false,
    this.errorMessage,
    this.successMessage,
    this.lastBackup,
    this.hasInterruptedRestore = false,
    this.remoteBackupCount = 0,
    this.remoteStorageBytes = 0,
    this.remoteBackups = const [],
    this.operationMessage,
    this.operationDetail,
    this.operationProgress,
    this.operationProcessedCount,
    this.operationTotalCount,
    this.operationEntityCount = 0,
    this.operationFileCount = 0,
    this.dropboxSessionExpired = false,
  });

  const BackupState.initial() : this();

  final BackupViewStatus viewStatus;
  final List<BackupManifest> backups;
  final bool isCreating;
  final bool isRestoring;
  final bool isUploading;
  final bool isLoadingRemote;
  final String? errorMessage;
  final String? successMessage;
  final BackupManifest? lastBackup;
  final bool hasInterruptedRestore;
  final int remoteBackupCount;
  final int remoteStorageBytes;
  final List<RemoteBackupInfo> remoteBackups;
  final String? operationMessage;
  final String? operationDetail;
  final double? operationProgress;
  final int? operationProcessedCount;
  final int? operationTotalCount;
  final int operationEntityCount;
  final int operationFileCount;
  final bool dropboxSessionExpired;

  BackupState copyWith({
    BackupViewStatus? viewStatus,
    List<BackupManifest>? backups,
    bool? isCreating,
    bool? isRestoring,
    bool? isUploading,
    bool? isLoadingRemote,
    String? errorMessage,
    bool clearError = false,
    String? successMessage,
    bool clearSuccess = false,
    BackupManifest? lastBackup,
    bool clearLastBackup = false,
    bool? hasInterruptedRestore,
    int? remoteBackupCount,
    int? remoteStorageBytes,
    List<RemoteBackupInfo>? remoteBackups,
    String? operationMessage,
    bool clearOperationMessage = false,
    String? operationDetail,
    bool clearOperationDetail = false,
    double? operationProgress,
    bool clearOperationProgress = false,
    int? operationProcessedCount,
    bool clearOperationProcessedCount = false,
    int? operationTotalCount,
    bool clearOperationTotalCount = false,
    int? operationEntityCount,
    int? operationFileCount,
    bool? dropboxSessionExpired,
  }) {
    return BackupState(
      viewStatus: viewStatus ?? this.viewStatus,
      backups: backups ?? this.backups,
      isCreating: isCreating ?? this.isCreating,
      isRestoring: isRestoring ?? this.isRestoring,
      isUploading: isUploading ?? this.isUploading,
      isLoadingRemote: isLoadingRemote ?? this.isLoadingRemote,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      successMessage: clearSuccess
          ? null
          : (successMessage ?? this.successMessage),
      lastBackup: clearLastBackup ? null : (lastBackup ?? this.lastBackup),
      hasInterruptedRestore:
          hasInterruptedRestore ?? this.hasInterruptedRestore,
      remoteBackupCount: remoteBackupCount ?? this.remoteBackupCount,
      remoteStorageBytes: remoteStorageBytes ?? this.remoteStorageBytes,
      remoteBackups: remoteBackups ?? this.remoteBackups,
      operationMessage: clearOperationMessage
          ? null
          : (operationMessage ?? this.operationMessage),
      operationDetail: clearOperationDetail
          ? null
          : (operationDetail ?? this.operationDetail),
      operationProgress: clearOperationProgress
          ? null
          : (operationProgress ?? this.operationProgress),
      operationProcessedCount: clearOperationProcessedCount
          ? null
          : (operationProcessedCount ?? this.operationProcessedCount),
      operationTotalCount: clearOperationTotalCount
          ? null
          : (operationTotalCount ?? this.operationTotalCount),
      operationEntityCount: operationEntityCount ?? this.operationEntityCount,
      operationFileCount: operationFileCount ?? this.operationFileCount,
      dropboxSessionExpired:
          dropboxSessionExpired ?? this.dropboxSessionExpired,
    );
  }
}
