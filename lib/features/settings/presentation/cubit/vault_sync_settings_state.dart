import 'package:pass_doc_manager/domain/vault_sync/entities/vault_sync_settings_entity.dart';
import 'package:pass_doc_manager/domain/vault_sync/entities/vault_sync_status_entity.dart';

enum VaultSyncSettingsViewStatus {
  initial,
  loading,
  ready,
  saving,
  syncing,
  error,
}

class VaultSyncSettingsState {
  const VaultSyncSettingsState({
    required this.viewStatus,
    required this.settings,
    required this.status,
    required this.errorMessage,
    required this.lastActionMessage,
  });

  const VaultSyncSettingsState.initial()
    : viewStatus = VaultSyncSettingsViewStatus.initial,
      settings = const VaultSyncSettingsEntity.defaults(),
      status = const VaultSyncStatusEntity.initial(),
      errorMessage = null,
      lastActionMessage = null;

  final VaultSyncSettingsViewStatus viewStatus;
  final VaultSyncSettingsEntity settings;
  final VaultSyncStatusEntity status;
  final String? errorMessage;
  final String? lastActionMessage;

  VaultSyncSettingsState copyWith({
    VaultSyncSettingsViewStatus? viewStatus,
    VaultSyncSettingsEntity? settings,
    VaultSyncStatusEntity? status,
    String? errorMessage,
    String? lastActionMessage,
  }) {
    return VaultSyncSettingsState(
      viewStatus: viewStatus ?? this.viewStatus,
      settings: settings ?? this.settings,
      status: status ?? this.status,
      errorMessage: errorMessage,
      lastActionMessage: lastActionMessage ?? this.lastActionMessage,
    );
  }
}
