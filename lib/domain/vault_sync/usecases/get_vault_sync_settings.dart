import 'package:pass_doc_manager/core/usecase/usecase.dart';
import 'package:pass_doc_manager/domain/vault_sync/entities/vault_sync_settings_entity.dart';
import 'package:pass_doc_manager/domain/vault_sync/repositories/vault_sync_repository.dart';

class GetVaultSyncSettings
    implements UseCase<VaultSyncSettingsEntity, NoParams> {
  GetVaultSyncSettings(this._repository);

  final VaultSyncRepository _repository;

  @override
  Future<VaultSyncSettingsEntity> call(NoParams params) {
    return _repository.getSettings();
  }
}

class NoParams {
  const NoParams();
}
