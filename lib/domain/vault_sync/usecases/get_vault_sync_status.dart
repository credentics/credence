import 'package:pass_doc_manager/core/usecase/usecase.dart';
import 'package:pass_doc_manager/domain/vault_sync/entities/vault_sync_status_entity.dart';
import 'package:pass_doc_manager/domain/vault_sync/repositories/vault_sync_repository.dart';

class GetVaultSyncStatus implements UseCase<VaultSyncStatusEntity, NoParams> {
  GetVaultSyncStatus(this._repository);

  final VaultSyncRepository _repository;

  @override
  Future<VaultSyncStatusEntity> call(NoParams params) {
    return _repository.getStatus();
  }
}

class NoParams {
  const NoParams();
}
