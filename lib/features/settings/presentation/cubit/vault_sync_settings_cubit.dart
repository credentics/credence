import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pass_doc_manager/app/di/injection.dart';
import 'package:pass_doc_manager/domain/vault_sync/entities/vault_sync_settings_entity.dart';
import 'package:pass_doc_manager/domain/vault_sync/usecases/get_vault_sync_settings.dart'
    as get_settings;
import 'package:pass_doc_manager/domain/vault_sync/usecases/get_vault_sync_status.dart'
    as get_status;
import 'package:pass_doc_manager/domain/vault_sync/usecases/run_vault_sync_now.dart'
    as run_sync;
import 'package:pass_doc_manager/domain/vault_sync/usecases/save_vault_sync_settings.dart';
import 'package:pass_doc_manager/features/settings/presentation/cubit/vault_sync_settings_state.dart';

class VaultSyncSettingsCubit extends Cubit<VaultSyncSettingsState> {
  VaultSyncSettingsCubit({
    get_settings.GetVaultSyncSettings? getSettings,
    get_status.GetVaultSyncStatus? getStatus,
    SaveVaultSyncSettings? saveSettings,
    run_sync.RunVaultSyncNow? runSyncNow,
  }) : _getSettings = getSettings ?? getIt(),
       _getStatus = getStatus ?? getIt(),
       _saveSettings = saveSettings ?? getIt(),
       _runSyncNow = runSyncNow ?? getIt(),
       super(const VaultSyncSettingsState.initial());

  final get_settings.GetVaultSyncSettings _getSettings;
  final get_status.GetVaultSyncStatus _getStatus;
  final SaveVaultSyncSettings _saveSettings;
  final run_sync.RunVaultSyncNow _runSyncNow;

  Future<void> load() async {
    emit(state.copyWith(viewStatus: VaultSyncSettingsViewStatus.loading));
    try {
      final settings = await _getSettings(const get_settings.NoParams());
      final syncStatus = await _getStatus(const get_status.NoParams());
      emit(
        state.copyWith(
          viewStatus: VaultSyncSettingsViewStatus.ready,
          settings: settings,
          status: syncStatus,
          errorMessage: null,
        ),
      );
    } catch (_) {
      debugPrint('[VaultSyncSettings] Failed to load sync settings');
      emit(
        state.copyWith(
          viewStatus: VaultSyncSettingsViewStatus.error,
          errorMessage: null, // UI uses l10n.syncErrorLoad
        ),
      );
    }
  }

  Future<void> save(VaultSyncSettingsEntity settings) async {
    emit(state.copyWith(viewStatus: VaultSyncSettingsViewStatus.saving));
    try {
      await _saveSettings(settings);
      final syncStatus = await _getStatus(const get_status.NoParams());
      emit(
        state.copyWith(
          viewStatus: VaultSyncSettingsViewStatus.ready,
          settings: settings,
          status: syncStatus,
          errorMessage: null,
          lastActionMessage: 'Settings saved.',
        ),
      );
    } catch (_) {
      debugPrint('[VaultSyncSettings] Failed to save settings');
      emit(
        state.copyWith(
          viewStatus: VaultSyncSettingsViewStatus.ready,
          errorMessage: null, // UI uses l10n.syncErrorSave
        ),
      );
    }
  }

  Future<void> syncNow() async {
    emit(state.copyWith(viewStatus: VaultSyncSettingsViewStatus.syncing));
    try {
      final result = await _runSyncNow(const run_sync.NoParams());
      final settings = await _getSettings(const get_settings.NoParams());
      final syncStatus = await _getStatus(const get_status.NoParams());
      emit(
        state.copyWith(
          viewStatus: VaultSyncSettingsViewStatus.ready,
          settings: settings,
          status: syncStatus,
          errorMessage: result.success ? null : result.message,
          lastActionMessage: result.message,
        ),
      );
    } catch (_) {
      debugPrint('[VaultSyncSettings] Failed to run sync');
      emit(
        state.copyWith(
          viewStatus: VaultSyncSettingsViewStatus.ready,
          errorMessage: null, // UI uses l10n.syncErrorRun
        ),
      );
    }
  }
}
