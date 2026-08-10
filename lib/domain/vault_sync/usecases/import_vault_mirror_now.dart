import 'package:pass_doc_manager/core/usecase/usecase.dart';
import 'package:pass_doc_manager/domain/vault_sync/entities/vault_sync_progress_entity.dart';
import 'package:pass_doc_manager/domain/vault_sync/entities/vault_sync_result_entity.dart';
import 'package:pass_doc_manager/domain/vault_sync/repositories/vault_sync_repository.dart';

class ImportVaultMirrorNow
    implements UseCase<VaultSyncResultEntity, ImportVaultMirrorParams> {
  ImportVaultMirrorNow(this._repository);

  final VaultSyncRepository _repository;

  @override
  Future<VaultSyncResultEntity> call(ImportVaultMirrorParams params) {
    return _repository.importNow(
      onProgress: params.onProgress,
      replaceLocal: params.replaceLocal,
    );
  }
}

class ImportVaultMirrorParams {
  const ImportVaultMirrorParams({this.onProgress, this.replaceLocal = false});

  final VaultSyncProgressCallback? onProgress;
  final bool replaceLocal;
}
