import 'package:pass_doc_manager/core/usecase/usecase.dart';
import 'package:pass_doc_manager/features/backup/domain/repositories/backup_repository.dart';

class DeleteBackup implements UseCase<void, DeleteBackupParams> {
  DeleteBackup(this._repository);
  final BackupRepository _repository;

  @override
  Future<void> call(DeleteBackupParams params) {
    return _repository.deleteBackup(params.backupId);
  }
}

class DeleteBackupParams {
  const DeleteBackupParams({required this.backupId});
  final String backupId;
}
