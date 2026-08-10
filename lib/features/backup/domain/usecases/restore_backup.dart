import 'package:pass_doc_manager/core/usecase/usecase.dart';
import 'package:pass_doc_manager/features/backup/domain/entities/backup_operation_progress.dart';
import 'package:pass_doc_manager/features/backup/domain/repositories/backup_repository.dart';

class RestoreBackup implements UseCase<void, RestoreBackupParams> {
  RestoreBackup(this._repository);
  final BackupRepository _repository;

  @override
  Future<void> call(RestoreBackupParams params) {
    return _repository.restoreFromBackup(
      backupId: params.backupId,
      passphrase: params.passphrase,
      onProgress: params.onProgress,
    );
  }
}

class RestoreBackupParams {
  const RestoreBackupParams({
    required this.backupId,
    required this.passphrase,
    this.onProgress,
  });
  final String backupId;
  final String passphrase;
  final BackupOperationProgressCallback? onProgress;
}
