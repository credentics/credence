import 'package:pass_doc_manager/domain/vault_sync/entities/vault_sync_settings_entity.dart';
import 'package:pass_doc_manager/domain/vault_sync/repositories/vault_sync_repository.dart';

class SaveVaultSyncSettings {
  SaveVaultSyncSettings(this._repository);

  final VaultSyncRepository _repository;

  Future<void> call(VaultSyncSettingsEntity settings) {
    return _repository.saveSettings(settings);
  }
}
