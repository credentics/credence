import 'package:pass_doc_manager/domain/vault_sync/entities/vault_sync_result_entity.dart';
import 'package:pass_doc_manager/domain/vault_sync/entities/vault_sync_head_check_result_entity.dart';
import 'package:pass_doc_manager/domain/vault_sync/entities/vault_sync_progress_entity.dart';
import 'package:pass_doc_manager/domain/vault_sync/entities/vault_sync_settings_entity.dart';
import 'package:pass_doc_manager/domain/vault_sync/entities/vault_sync_status_entity.dart';

abstract class VaultSyncRepository {
  Future<VaultSyncSettingsEntity> getSettings();

  Future<void> saveSettings(VaultSyncSettingsEntity settings);

  Future<VaultSyncStatusEntity> getStatus();

  Future<VaultSyncResultEntity> syncNow({
    VaultSyncProgressCallback? onProgress,
    bool allowDeletes = false,
  });

  Future<VaultSyncResultEntity> importNow({
    VaultSyncProgressCallback? onProgress,
    bool replaceLocal = false,
  });

  Future<VaultSyncHeadCheckResultEntity> checkRemoteHead();

  Future<VaultSyncResultEntity> syncFromRemoteNow({
    VaultSyncProgressCallback? onProgress,
  });

  Future<VaultSyncResultEntity> syncToRemoteNow({
    VaultSyncProgressCallback? onProgress,
  });
}
