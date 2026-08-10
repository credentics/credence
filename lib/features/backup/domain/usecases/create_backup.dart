import 'package:pass_doc_manager/core/usecase/usecase.dart';
import 'package:pass_doc_manager/features/backup/domain/entities/backup_manifest.dart';
import 'package:pass_doc_manager/features/backup/domain/entities/backup_operation_progress.dart';
import 'package:pass_doc_manager/features/backup/domain/repositories/backup_repository.dart';

class CreateBackup implements UseCase<BackupManifest, CreateBackupParams> {
  CreateBackup(this._repository);
  final BackupRepository _repository;

  @override
  Future<BackupManifest> call(CreateBackupParams params) {
    return _repository.createBackup(
      passphrase: params.passphrase,
      onProgress: params.onProgress,
    );
  }
}

class CreateBackupParams {
  const CreateBackupParams({required this.passphrase, this.onProgress});
  final String passphrase;
  final BackupOperationProgressCallback? onProgress;
}
