import 'package:pass_doc_manager/core/usecase/usecase.dart';
import 'package:pass_doc_manager/domain/vault_sync/entities/vault_sync_progress_entity.dart';
import 'package:pass_doc_manager/domain/vault_sync/entities/vault_sync_result_entity.dart';
import 'package:pass_doc_manager/domain/vault_sync/repositories/vault_sync_repository.dart';

class RunVaultSyncNow implements UseCase<VaultSyncResultEntity, NoParams> {
  RunVaultSyncNow(this._repository);

  final VaultSyncRepository _repository;

  @override
  Future<VaultSyncResultEntity> call(NoParams params) {
    return _repository.syncNow(
      onProgress: params.onProgress,
      allowDeletes: params.allowDeletes,
    );
  }
}

class NoParams {
  const NoParams({this.onProgress, this.allowDeletes = false});

  final VaultSyncProgressCallback? onProgress;
  final bool allowDeletes;
}
