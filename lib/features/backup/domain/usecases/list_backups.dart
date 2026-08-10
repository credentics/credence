import 'package:pass_doc_manager/core/usecase/usecase.dart';
import 'package:pass_doc_manager/features/backup/domain/entities/backup_manifest.dart';
import 'package:pass_doc_manager/features/backup/domain/repositories/backup_repository.dart';

class ListBackups implements UseCase<List<BackupManifest>, ListBackupsParams> {
  ListBackups(this._repository);
  final BackupRepository _repository;

  @override
  Future<List<BackupManifest>> call(ListBackupsParams params) {
    return _repository.listBackups();
  }
}

class ListBackupsParams {
  const ListBackupsParams();
}
