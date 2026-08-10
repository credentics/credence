import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pass_doc_manager/app/di/injection.dart';
import 'package:pass_doc_manager/app/platform/background_task_service.dart';
import 'package:pass_doc_manager/features/backup/presentation/cubit/backup_live_activity_controller.dart';
import 'package:pass_doc_manager/features/backup/presentation/cubit/dropbox_session_manager.dart';
import 'package:pass_doc_manager/features/backup/presentation/cubit/restore_recovery_service.dart';
import 'package:pass_doc_manager/features/backup/presentation/cubit/cloud_sync_service.dart';
import 'package:pass_doc_manager/app/sync/vault_data_refresh_signal.dart';
import 'package:pass_doc_manager/data/vault_sync/dtos/vault_sync_prefs_dto.dart';
import 'package:pass_doc_manager/data/vault_sync/datasources/local/vault_sync_prefs_local_data_source.dart';
import 'package:pass_doc_manager/data/vault_sync/datasources/local/vault_sync_journal_local_data_source.dart';
import 'package:pass_doc_manager/features/backup/data/datasources/local/backup_local_data_source.dart';
import 'package:pass_doc_manager/features/backup/domain/entities/backup_operation_progress.dart';
import 'package:pass_doc_manager/features/backup/domain/repositories/backup_repository.dart';
import 'package:pass_doc_manager/features/backup/domain/usecases/create_backup.dart';
import 'package:pass_doc_manager/features/backup/domain/usecases/delete_backup.dart';
import 'package:pass_doc_manager/features/backup/domain/usecases/list_backups.dart';
import 'package:pass_doc_manager/features/backup/domain/usecases/restore_backup.dart';
import 'package:pass_doc_manager/features/backup/domain/entities/cloud_provider_type.dart';
import 'package:pass_doc_manager/features/backup/infrastructure/providers/dropbox_backup_provider.dart';
import 'package:pass_doc_manager/features/backup/infrastructure/services/backup_passphrase_service.dart';
import 'package:pass_doc_manager/features/backup/infrastructure/services/backup_remote_index.dart';
import 'package:pass_doc_manager/features/backup/infrastructure/services/backup_scheduler.dart';
import 'package:dio/dio.dart';
import 'package:pass_doc_manager/features/backup/presentation/cubit/backup_state.dart';
import 'package:pass_doc_manager/data/vault_sync/mirror/vault_mirror_import_source.dart';
import 'package:pass_doc_manager/data/vault_sync/mirror/vault_mirror_workspace.dart';
import 'package:pass_doc_manager/domain/vault_sync/usecases/import_vault_mirror_now.dart';
import 'package:pass_doc_manager/domain/vault_sync/usecases/run_vault_sync_now.dart';

/// Master kill switch for the auto-backup loop. Set to `true` to disable.
///
/// When `false`, [BackupCubit.autoBackupIfNeeded] runs a scheduled backup once
/// the configured interval has elapsed and a passphrase is stored in secure
/// storage. It is safe to leave enabled:
///  * the backup pipeline is the streaming mirror writer — binary attachments
///    are copied file-by-file via `openRead`, never buffered into memory, so
///    it does not OOM on a large vault (the old whole-vault → JSON → ZIP →
///    in-memory-encrypt pipeline that this switch was created to gate is gone);
///  * the trigger is deferred off the resume frame and debounced against rapid
///    background→foreground cycles (see `_scheduleAutoBackupCheck`);
///  * it skips while any user-initiated create/upload/restore is running.
///
/// Flip back to `true` if a device shows resume-time jank; manual backup,
/// restore, list, delete, and cloud upload are unaffected either way.
const bool kAutoBackupDisabled = false;

class BackupCubit extends Cubit<BackupState> {
  BackupCubit({
    CreateBackup? createBackup,
    ListBackups? listBackups,
    DeleteBackup? deleteBackup,
    RestoreBackup? restoreBackup,
  }) : _createBackup = createBackup,
       _listBackups = listBackups,
       _deleteBackup = deleteBackup,
       _restoreBackup = restoreBackup,
       super(const BackupState.initial());

  CreateBackup? _createBackup;
  ListBackups? _listBackups;
  DeleteBackup? _deleteBackup;
  RestoreBackup? _restoreBackup;
  final BackupLiveActivityController _liveActivity =
      BackupLiveActivityController();
  final DropboxSessionManager _dropboxSession = DropboxSessionManager();
  final RestoreRecoveryService _restoreRecovery = RestoreRecoveryService();
  final CloudSyncService _cloudSync = const CloudSyncService();

  /// Returns true if [error] indicates a Dropbox 401/expired session.
  bool _isDropboxAuthError(Object error) =>
      DropboxSessionManager.isAuthError(error);

  /// Clears the cached Dropbox token and marks the session expired.
  Future<void> _markDropboxSessionExpired() async {
    final hadDropboxSession = await _dropboxSession.expireSession();
    if (isClosed) return;
    emit(state.copyWith(dropboxSessionExpired: hadDropboxSession));
  }

  /// Resets the expired flag (after a successful reconnect).
  void clearDropboxSessionExpired() {
    emit(state.copyWith(dropboxSessionExpired: false));
  }

  Future<void> _ensureInitialized() async {
    _createBackup ??= getIt<CreateBackup>();
    _listBackups ??= getIt<ListBackups>();
    _deleteBackup ??= getIt<DeleteBackup>();
    _restoreBackup ??= getIt<RestoreBackup>();
  }

  Future<void> load() async {
    emit(
      state.copyWith(viewStatus: BackupViewStatus.loading, clearError: true),
    );
    try {
      await _ensureInitialized();
      final backups = await _listBackups!(const ListBackupsParams());

      // Check for interrupted restore
      final hasInterrupted = await _checkForInterruptedRestore();

      emit(
        state.copyWith(
          viewStatus: BackupViewStatus.ready,
          backups: backups,
          lastBackup: backups.isNotEmpty ? backups.first : null,
          hasInterruptedRestore: hasInterrupted,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          viewStatus: BackupViewStatus.error,
          errorMessage: null, // UI uses l10n.backupErrorLoad
        ),
      );
    }
  }

  /// Checks if a previous restore was interrupted by looking for
  /// an orphaned rollback directory.
  Future<bool> _checkForInterruptedRestore() =>
      _restoreRecovery.hasInterruptedRestore();

  /// Dismisses the interrupted restore warning from the UI.
  void dismissInterruptedRestore() {
    emit(state.copyWith(hasInterruptedRestore: false));
  }

  /// Rolls back to the pre-restore state by removing the rollback directory.
  Future<void> rollbackInterruptedRestore() async {
    try {
      await _restoreRecovery.discardRollback();
      emit(state.copyWith(hasInterruptedRestore: false));
    } catch (e) {
      emit(
        state.copyWith(
          errorMessage: null, // UI uses l10n.backupErrorRollback
        ),
      );
    }
  }

  Future<bool> createBackup(String passphrase) async {
    _startLiveActivity(
      operation: 'Backup',
      provider: 'Local',
      message: 'Preparing backup',
      detail: 'Loading current device state.',
      progress: 0.03,
    );
    emit(
      state.copyWith(
        isCreating: true,
        clearError: true,
        clearSuccess: true,
        operationMessage: 'Preparing backup',
        operationDetail: 'Loading current device state and backup metadata.',
        operationProgress: 0.03,
        clearOperationProcessedCount: true,
        clearOperationTotalCount: true,
        operationEntityCount: 0,
        operationFileCount: 0,
      ),
    );
    try {
      return await _withProtectedVaultOperation<
        bool
      >('Credence local backup', () async {
        await _ensureInitialized();
        final manifest = await _createBackup!(
          CreateBackupParams(
            passphrase: passphrase,
            onProgress: (progress) => _applyOperationProgress(
              progress,
              isCreating: true,
              isRestoring: false,
            ),
          ),
        );
        await load();
        final completionMessage = manifest.warningMessage == null
            ? 'Backup complete'
            : 'Backup complete with warnings';
        final completionDetail =
            manifest.warningMessage ??
            'Saved ${manifest.entityCount} records and ${manifest.fileCount} files.';
        _completeLiveActivity(
          message: completionMessage,
          detail: completionDetail,
        );
        emit(
          state.copyWith(
            isCreating: false,
            lastBackup: manifest,
            operationMessage: completionMessage,
            operationDetail: completionDetail,
            operationProgress: 1,
            operationEntityCount: manifest.entityCount,
            operationFileCount: manifest.fileCount,
          ),
        );
        return true;
      });
    } catch (e) {
      _failLiveActivity(
        message: 'Backup failed',
        detail: _normalizeErrorMessage(e),
      );
      emit(
        state.copyWith(
          isCreating: false,
          errorMessage: _normalizeErrorMessage(e),
        ),
      );
      return false;
    }
  }

  Future<bool> restoreBackup(String backupId, String passphrase) async {
    _startLiveActivity(
      operation: 'Restore',
      provider: 'Local',
      message: 'Opening backup archive',
      detail: 'Preparing the selected backup.',
      progress: 0.04,
    );
    emit(
      state.copyWith(
        isRestoring: true,
        clearError: true,
        clearSuccess: true,
        operationMessage: 'Opening backup archive',
        operationDetail: 'Preparing the selected backup for restore.',
        operationProgress: 0.04,
        clearOperationProcessedCount: true,
        clearOperationTotalCount: true,
      ),
    );
    try {
      return await _withProtectedVaultOperation<bool>(
        'Credence local restore',
        () async {
          await _ensureInitialized();
          await _restoreBackup!(
            RestoreBackupParams(
              backupId: backupId,
              passphrase: passphrase,
              onProgress: (progress) => _applyOperationProgress(
                progress,
                isCreating: false,
                isRestoring: true,
              ),
            ),
          );
          await load();
          VaultDataRefreshSignal.notifyRestoreCompleted();
          _completeLiveActivity(
            message: 'Restore complete',
            detail: 'The selected backup has been restored locally.',
          );
          emit(
            state.copyWith(
              isRestoring: false,
              operationMessage: 'Restore complete',
              operationDetail: 'The selected backup has been restored locally.',
              operationProgress: 1,
            ),
          );
          return true;
        },
      );
    } catch (e) {
      _failLiveActivity(
        message: 'Restore failed',
        detail: _normalizeErrorMessage(e),
      );
      emit(
        state.copyWith(
          isRestoring: false,
          errorMessage: _normalizeErrorMessage(e),
        ),
      );
      return false;
    }
  }

  Future<T> _withProtectedVaultOperation<T>(
    String reason,
    Future<T> Function() operation,
  ) async {
    final lease = await BackgroundTaskService.protect(reason);
    try {
      return await operation();
    } finally {
      await lease.dispose();
    }
  }

  Future<void> deleteBackup(String backupId) async {
    try {
      await _ensureInitialized();
      await _deleteBackup!(DeleteBackupParams(backupId: backupId));
      await load();
    } catch (e) {
      debugPrint('[BackupCubit] Delete failed: $e');
      emit(
        state.copyWith(errorMessage: null),
      ); // UI uses l10n.backupErrorDelete
    }
  }

  Future<void> uploadToCloud({bool allowDeletes = false}) async {
    BackgroundTaskLease? operationLease;
    CloudProviderType? activeProvider;
    // When the remote mirror can't be verified (remoteBackupCount == -1) —
    // e.g. the cloud was cleared or still holds a pre-rebrand mirror — this
    // push must re-seed the ENTIRE mirror, not a delta against a stale
    // baseline. We clear the sync journal below so every entity/file counts as
    // new. (Pair with an empty remote dir for a fully complete upload.)
    final forceFullUpload = state.remoteBackupCount < 0;
    emit(
      state.copyWith(
        isUploading: true,
        clearError: true,
        operationMessage: 'Preparing sync...',
        operationProgress: 0.0,
        operationProcessedCount: 0,
        operationTotalCount: 0,
      ),
    );
    try {
      await _ensureInitialized();
      final syncPrefs = getIt<VaultSyncPrefsLocalDataSource>();
      var prefs = await syncPrefs.readPrefs();
      final provider = _activeCloudProvider(prefs);
      activeProvider = provider;
      final providerLabel = provider.label;
      prefs = await _refreshProviderTokenIfNeeded(syncPrefs, prefs, provider);
      final token = _providerToken(prefs, provider);
      operationLease = await BackgroundTaskService.protect(
        'Credence $providerLabel sync',
      );
      if (token.trim().isEmpty) {
        emit(
          state.copyWith(
            isUploading: false,
            clearOperationMessage: true,
            clearOperationProgress: true,
            clearOperationProcessedCount: true,
            clearOperationTotalCount: true,
            errorMessage: 'Connect $providerLabel before syncing.',
          ),
        );
        return;
      }
      _startLiveActivity(
        operation: 'Sync',
        provider: providerLabel,
        message: 'Preparing sync',
        detail: 'Incoming changes are imported first; only deltas are sent.',
        progress: 0.03,
      );
      final directory = _mirrorDirectory(prefs);
      await syncPrefs.writePrefs(
        prefs.copyWith(
          targetType: _providerTargetValue(provider),
          selectedCloudProvider: provider.key,
          dropboxAccessToken: provider == CloudProviderType.dropbox
              ? token.trim()
              : prefs.dropboxAccessToken,
          googleDriveAccessToken: provider == CloudProviderType.googleDrive
              ? token.trim()
              : prefs.googleDriveAccessToken,
          dropboxDirectoryPath: directory,
        ),
      );
      emit(
        state.copyWith(
          operationMessage: 'Synchronizing with $providerLabel...',
          operationDetail:
              'Incoming changes are imported first; only changed or missing vault files are transferred.',
          operationProgress: 0.10,
          operationProcessedCount: 0,
          operationTotalCount: 1,
        ),
      );
      if (forceFullUpload) {
        final journal = getIt<VaultSyncJournalLocalDataSource>();
        await journal.writeContentIndex(const <String, String>{});
        await journal.writeContentPayloadIndex(
          const <String, Map<String, dynamic>>{},
        );
        await journal.clearLocalOperations();
        debugPrint(
          '[BackupCubit] Force-full upload: cleared sync journal so the '
          'complete mirror is re-uploaded.',
        );
      }
      final result = await getIt<RunVaultSyncNow>()(
        NoParams(
          allowDeletes: allowDeletes,
          onProgress: (progress) => _applyOperationProgress(
            BackupOperationProgress(
              message: progress.message,
              detail: progress.detail,
              progress: progress.progress,
              processedCount: progress.processedCount,
              totalCount: progress.totalCount,
              entityCount: progress.entityCount,
              fileCount: progress.fileCount,
            ),
            isCreating: false,
            isRestoring: false,
            isUploading: true,
          ),
        ),
      );
      if (!result.success) {
        throw StateError(result.message);
      }
      emit(
        state.copyWith(
          operationMessage: 'Synchronizing changes to $providerLabel...',
          operationDetail: result.message,
          operationProgress: 1,
          operationProcessedCount: 1,
          operationTotalCount: 1,
        ),
      );
      debugPrint('[BackupCubit] Upload to cloud completed');

      await refreshRemoteStatus();
      _completeLiveActivity(message: 'Sync complete', detail: result.message);

      emit(
        state.copyWith(
          isUploading: false,
          clearOperationMessage: true,
          clearOperationDetail: true,
          clearOperationProgress: true,
          clearOperationProcessedCount: true,
          clearOperationTotalCount: true,
          successMessage: null, // UI uses l10n.backupSuccessUpload
        ),
      );
    } catch (e) {
      debugPrint('[BackupCubit] Upload to cloud failed: $e');
      if (activeProvider == CloudProviderType.dropbox &&
          _isDropboxAuthError(e)) {
        await _markDropboxSessionExpired();
      }
      _failLiveActivity(
        message: 'Sync failed',
        detail: _normalizeErrorMessage(e, provider: activeProvider),
      );
      emit(
        state.copyWith(
          isUploading: false,
          clearOperationMessage: true,
          clearOperationDetail: true,
          clearOperationProgress: true,
          clearOperationProcessedCount: true,
          clearOperationTotalCount: true,
          errorMessage: _normalizeErrorMessage(e),
        ),
      );
    } finally {
      await operationLease?.dispose();
    }
  }

  Future<void> refreshRemoteStatus() async {
    try {
      final syncPrefs = getIt<VaultSyncPrefsLocalDataSource>();
      var prefs = await syncPrefs.readPrefs();
      final provider = _activeCloudProvider(prefs);
      prefs = await _refreshProviderTokenIfNeeded(syncPrefs, prefs, provider);
      final token = _providerToken(prefs, provider);
      if (token.isEmpty) return;
      await _refreshRemoteStatusForProvider(prefs, provider, token);
    } catch (e) {
      debugPrint('[BackupCubit] Remote status refresh failed: $e');
    }
  }

  Future<void> _refreshRemoteStatusForProvider(
    VaultSyncPrefsDto prefs,
    CloudProviderType provider,
    String token,
  ) async {
    emit(state.copyWith(isLoadingRemote: true));
    try {
      final manifestText = await _downloadMirrorManifestText(
        prefs: prefs,
        provider: provider,
        token: token,
      );
      final manifest = jsonDecode(manifestText);
      final manifestMap = manifest is Map<String, dynamic>
          ? manifest
          : Map<String, dynamic>.from(manifest as Map);
      final contentChecksum = '${manifestMap['content_checksum'] ?? ''}'.trim();
      final revision = (manifestMap['revision'] as int?) ?? 0;
      final files = manifestMap['files'];
      final fileCount = files is List ? files.length : 0;
      final totalBytes = files is List
          ? files.whereType<Map>().fold<int>(
              0,
              (sum, file) => sum + ((file['size_bytes'] as int?) ?? 0),
            )
          : 0;
      final acceptedChecksum = prefs.lastUploadedChecksum.trim();
      final remoteMatchesAccepted =
          contentChecksum.isNotEmpty && contentChecksum == acceptedChecksum;
      try {
        final syncPrefs = getIt<VaultSyncPrefsLocalDataSource>();
        await syncPrefs.writePrefs(
          prefs.copyWith(
            lastRemoteCheckedAtIso: DateTime.now().toUtc().toIso8601String(),
            lastRemoteRevision: revision,
            lastRemoteChecksum: contentChecksum,
            lastRemoteDeviceId: '${manifestMap['device_id'] ?? ''}'.trim(),
            lastObservedRemoteRevision: remoteMatchesAccepted && revision > 0
                ? revision
                : prefs.lastObservedRemoteRevision,
          ),
        );
      } catch (_) {
        // Remote status display should not fail because prefs could not update.
      }
      emit(
        state.copyWith(
          isLoadingRemote: false,
          remoteBackupCount: fileCount,
          remoteStorageBytes: totalBytes,
          remoteBackups: [
            RemoteBackupInfo(
              fileName: 'Credence mirror',
              sizeBytes: totalBytes,
              modifiedAt:
                  DateTime.tryParse(
                    '${manifestMap['generated_at_iso'] ?? ''}',
                  ) ??
                  DateTime.now(),
            ),
          ],
        ),
      );
    } catch (e) {
      debugPrint('[BackupCubit] Remote status check failed: $e');
      if (provider == CloudProviderType.dropbox && _isDropboxAuthError(e)) {
        await _markDropboxSessionExpired();
      }
      emit(
        state.copyWith(
          isLoadingRemote: false,
          remoteBackupCount: -1,
          errorMessage: null, // Remote status errors are non-critical
        ),
      );
    }
  }

  Future<bool> restoreFromCloud(
    RemoteBackupInfo backup,
    String passphrase,
  ) async {
    CloudProviderType? activeProvider;
    BackgroundTaskLease? operationLease;
    emit(
      state.copyWith(
        isRestoring: true,
        clearError: true,
        clearSuccess: true,
        operationMessage: 'Connecting to cloud backup',
        operationDetail: 'Preparing to download the selected remote archive.',
        operationProgress: 0.03,
        clearOperationProcessedCount: true,
        clearOperationTotalCount: true,
      ),
    );
    try {
      final syncPrefs = getIt<VaultSyncPrefsLocalDataSource>();
      var prefs = await syncPrefs.readPrefs();
      final provider = _activeCloudProvider(prefs);
      activeProvider = provider;
      final providerLabel = provider.label;
      prefs = await _refreshProviderTokenIfNeeded(syncPrefs, prefs, provider);
      final token = _providerToken(prefs, provider);
      operationLease = await BackgroundTaskService.protect(
        'Credence $providerLabel restore',
      );
      if (token.isEmpty) {
        final message =
            '$providerLabel is not connected. Reconnect it, then try restoring again.';
        emit(
          state.copyWith(
            isRestoring: false,
            operationMessage: 'Restore blocked',
            operationDetail: message,
            errorMessage: message,
          ),
        );
        return false;
      }
      _startLiveActivity(
        operation: 'Restore',
        provider: providerLabel,
        message: 'Connecting to cloud backup',
        detail: 'Preparing to download the selected backup.',
        progress: 0.03,
      );

      if (backup.fileName == 'Credence mirror') {
        // Point at whichever directory actually holds the mirror. During the
        // /Vaultic → /Credence transition the active pointer may be the empty
        // /Credence folder while the real mirror is still at /Vaultic.
        final directory = (await _resolveMirror(
          prefs: prefs,
          provider: provider,
          token: token,
        )).directory;
        await syncPrefs.writePrefs(
          prefs.copyWith(
            targetType: _providerTargetValue(provider),
            selectedCloudProvider: provider.key,
            dropboxAccessToken: provider == CloudProviderType.dropbox
                ? token
                : prefs.dropboxAccessToken,
            googleDriveAccessToken: provider == CloudProviderType.googleDrive
                ? token
                : prefs.googleDriveAccessToken,
            dropboxDirectoryPath: directory,
          ),
        );
        final result = await getIt<ImportVaultMirrorNow>()(
          ImportVaultMirrorParams(
            replaceLocal: true,
            onProgress: (progress) => _applyOperationProgress(
              BackupOperationProgress(
                message: progress.message,
                detail: progress.detail,
                progress: progress.progress,
                processedCount: progress.processedCount,
                totalCount: progress.totalCount,
                entityCount: progress.entityCount,
                fileCount: progress.fileCount,
              ),
              isCreating: false,
              isRestoring: true,
            ),
          ),
        );
        if (!result.success) {
          throw StateError(result.message);
        }
        await load();
        VaultDataRefreshSignal.notifyRestoreCompleted();
        _completeLiveActivity(
          message: 'Restore complete',
          detail: result.message,
        );
        emit(
          state.copyWith(
            isRestoring: false,
            operationMessage: 'Restore complete',
            operationDetail: result.message,
            operationProgress: 1,
          ),
        );
        return true;
      }

      if (provider != CloudProviderType.dropbox) {
        throw StateError(
          'Legacy encrypted cloud archives can only be restored from Dropbox. Use the Credence mirror for $providerLabel.',
        );
      }

      _applyOperationProgress(
        const BackupOperationProgress(
          message: 'Downloading cloud backup',
          detail: 'Fetching the encrypted archive and manifest from Dropbox.',
          progress: 0.08,
        ),
        isCreating: false,
        isRestoring: true,
      );
      debugPrint('[CloudRestore] Downloading ${backup.fileName}...');
      final dropboxProvider = DropboxBackupProvider(
        dio: Dio(),
        accessToken: token,
      );
      final backupId = backup.fileName.replaceAll('.enc', '');
      Future<Uint8List> downloadArchive(String fileName) {
        return dropboxProvider.downloadFile(
          remotePath: '${BackupRemoteIndex.backupsDir}/$fileName',
        );
      }

      final results = await Future.wait([
        downloadArchive(backup.fileName),
        downloadArchive('$backupId.manifest.json'),
      ]);
      final encryptedBytes = results[0];
      final manifestBytes = results[1];
      debugPrint('[CloudRestore] Downloaded archive + manifest');

      _applyOperationProgress(
        const BackupOperationProgress(
          message: 'Reading cloud manifest',
          detail: 'Inspecting the downloaded restore metadata.',
          progress: 0.14,
        ),
        isCreating: false,
        isRestoring: true,
      );
      final manifestJson = String.fromCharCodes(manifestBytes);
      final manifestMap = Map<String, dynamic>.from(
        jsonDecode(manifestJson) as Map,
      );

      final repo = getIt<BackupRepository>();
      await repo.restoreFromCloudDownload(
        encryptedBytes: encryptedBytes,
        passphrase: passphrase,
        manifestMap: manifestMap,
        onProgress: (progress) => _applyOperationProgress(
          progress,
          isCreating: false,
          isRestoring: true,
        ),
      );

      debugPrint('[CloudRestore] Restore completed');

      await load();
      VaultDataRefreshSignal.notifyRestoreCompleted();
      _completeLiveActivity(
        message: 'Restore complete',
        detail: 'The cloud backup has been restored locally.',
      );
      emit(
        state.copyWith(
          isRestoring: false,
          operationMessage: 'Restore complete',
          operationDetail: 'The cloud backup has been restored locally.',
          operationProgress: 1,
        ),
      );
      return true;
    } catch (e) {
      debugPrint('[CloudRestore] Restore failed: $e');
      if (activeProvider == CloudProviderType.dropbox &&
          _isDropboxAuthError(e)) {
        await _markDropboxSessionExpired();
      }
      final message = _normalizeErrorMessage(e, provider: activeProvider);
      _failLiveActivity(message: 'Restore failed', detail: message);
      emit(
        state.copyWith(
          isRestoring: false,
          operationMessage: 'Restore failed',
          operationDetail: message,
          errorMessage: message,
        ),
      );
      return false;
    } finally {
      await operationLease?.dispose();
    }
  }

  Future<bool> discardLocalChangesFromCloud() async {
    CloudProviderType? activeProvider;
    BackgroundTaskLease? operationLease;
    emit(
      state.copyWith(
        isRestoring: true,
        clearError: true,
        clearSuccess: true,
        operationMessage: 'Preparing to discard local changes',
        operationDetail: 'The selected cloud mirror will be restored locally.',
        operationProgress: 0.03,
        clearOperationProcessedCount: true,
        clearOperationTotalCount: true,
      ),
    );
    try {
      final syncPrefs = getIt<VaultSyncPrefsLocalDataSource>();
      var prefs = await syncPrefs.readPrefs();
      final provider = _activeCloudProvider(prefs);
      activeProvider = provider;
      final providerLabel = provider.label;
      prefs = await _refreshProviderTokenIfNeeded(syncPrefs, prefs, provider);
      final token = _providerToken(prefs, provider);
      operationLease = await BackgroundTaskService.protect(
        'Credence $providerLabel discard local changes',
      );
      if (token.isEmpty) {
        final message =
            '$providerLabel is not connected. Reconnect it, then try again.';
        emit(
          state.copyWith(
            isRestoring: false,
            operationMessage: 'Discard blocked',
            operationDetail: message,
            errorMessage: message,
          ),
        );
        return false;
      }

      _startLiveActivity(
        operation: 'Restore',
        provider: providerLabel,
        message: 'Discarding local changes',
        detail: 'Restoring $providerLabel as the source of truth.',
        progress: 0.03,
      );

      final directory = _mirrorDirectory(prefs);
      await syncPrefs.writePrefs(
        prefs.copyWith(
          targetType: _providerTargetValue(provider),
          selectedCloudProvider: provider.key,
          dropboxAccessToken: provider == CloudProviderType.dropbox
              ? token
              : prefs.dropboxAccessToken,
          googleDriveAccessToken: provider == CloudProviderType.googleDrive
              ? token
              : prefs.googleDriveAccessToken,
          dropboxDirectoryPath: directory,
        ),
      );

      final result = await getIt<ImportVaultMirrorNow>()(
        ImportVaultMirrorParams(
          replaceLocal: true,
          onProgress: (progress) => _applyOperationProgress(
            BackupOperationProgress(
              message: progress.message,
              detail: progress.detail,
              progress: progress.progress,
              processedCount: progress.processedCount,
              totalCount: progress.totalCount,
              entityCount: progress.entityCount,
              fileCount: progress.fileCount,
            ),
            isCreating: false,
            isRestoring: true,
          ),
        ),
      );
      if (!result.success) {
        throw StateError(result.message);
      }

      await load();
      await refreshRemoteStatus();
      VaultDataRefreshSignal.notifyRestoreCompleted();
      _completeLiveActivity(
        message: 'Local changes discarded',
        detail: result.message,
      );
      emit(
        state.copyWith(
          isRestoring: false,
          operationMessage: 'Local changes discarded',
          operationDetail: result.message,
          operationProgress: 1,
        ),
      );
      return true;
    } catch (e) {
      debugPrint('[CloudDiscard] Discard local changes failed: $e');
      if (activeProvider == CloudProviderType.dropbox &&
          _isDropboxAuthError(e)) {
        await _markDropboxSessionExpired();
      }
      final message = _normalizeErrorMessage(e, provider: activeProvider);
      _failLiveActivity(message: 'Discard failed', detail: message);
      emit(
        state.copyWith(
          isRestoring: false,
          operationMessage: 'Discard failed',
          operationDetail: message,
          errorMessage: message,
        ),
      );
      return false;
    } finally {
      await operationLease?.dispose();
    }
  }

  // Thin delegates to [CloudSyncService]; call sites are unchanged.
  CloudProviderType _activeCloudProvider(VaultSyncPrefsDto prefs) =>
      _cloudSync.activeProvider(prefs);

  Future<VaultSyncPrefsDto> _refreshProviderTokenIfNeeded(
    VaultSyncPrefsLocalDataSource syncPrefs,
    VaultSyncPrefsDto prefs,
    CloudProviderType provider,
  ) => _cloudSync.refreshTokenIfNeeded(syncPrefs, prefs, provider);

  String _providerToken(VaultSyncPrefsDto prefs, CloudProviderType provider) =>
      _cloudSync.token(prefs, provider);

  String _providerTargetValue(CloudProviderType provider) =>
      _cloudSync.targetValue(provider);

  String _mirrorDirectory(VaultSyncPrefsDto prefs) =>
      _cloudSync.mirrorDirectory(prefs);

  /// Locates the mirror at the configured directory, returning that directory
  /// and its manifest text.
  Future<({String directory, String manifestText})> _resolveMirror({
    required VaultSyncPrefsDto prefs,
    required CloudProviderType provider,
    required String token,
  }) async {
    final directory = _mirrorDirectory(prefs);
    final manifestText = await _downloadMirrorManifestFrom(
      directory: directory,
      provider: provider,
      token: token,
    );
    return (directory: directory, manifestText: manifestText);
  }

  Future<String> _downloadMirrorManifestText({
    required VaultSyncPrefsDto prefs,
    required CloudProviderType provider,
    required String token,
  }) async =>
      (await _resolveMirror(prefs: prefs, provider: provider, token: token))
          .manifestText;

  Future<String> _downloadMirrorManifestFrom({
    required String directory,
    required CloudProviderType provider,
    required String token,
  }) async {
    const relativePath = VaultMirrorWorkspace.manifestPath;
    switch (provider) {
      case CloudProviderType.dropbox:
        return utf8.decode(
          await DropboxBackupProvider(
            dio: Dio(),
            accessToken: token,
          ).downloadFile(remotePath: '$directory/$relativePath'),
        );
      case CloudProviderType.googleDrive:
        return GoogleDriveVaultMirrorImportSource(
          dio: Dio(),
          accessToken: token,
          directoryPath: directory,
        ).readText(relativePath);
      case CloudProviderType.iCloud:
        throw StateError('iCloud mirror status is not available yet.');
    }
  }

  void clearSuccessMessage() {
    emit(state.copyWith(clearSuccess: true));
  }

  /// Silently triggers an auto-backup if the scheduler says one is due
  /// and a passphrase is stored in secure storage.
  /// Safe to call from anywhere (app resume, page load, etc.).
  Future<void> autoBackupIfNeeded() async {
    if (kAutoBackupDisabled) {
      debugPrint('[AutoBackup] Skipped: kAutoBackupDisabled');
      return;
    }
    try {
      await _ensureInitialized();
      final scheduler = BackupScheduler(
        localDataSource: getIt<BackupLocalDataSource>(),
      );
      if (!await scheduler.shouldAutoBackup()) return;

      // Need stored passphrase for auto-backup
      final passphrase = await _getStoredPassphrase();
      if (passphrase == null) {
        return; // Can't auto-backup without stored passphrase
      }

      debugPrint('[AutoBackup] Triggering auto-backup');
      await createBackup(passphrase);
      await scheduler.recordBackupCompleted();
      debugPrint('[AutoBackup] Auto-backup completed');
    } catch (e) {
      debugPrint('[AutoBackup] Failed: $e');
    }
  }

  /// Reads the backup passphrase from secure storage.
  /// Returns null if not stored.
  Future<String?> _getStoredPassphrase() async {
    try {
      return await BackupPassphraseService.getStoredPassphrase();
    } catch (e) {
      debugPrint('[AutoBackup] Failed to read stored passphrase: $e');
      return null;
    }
  }

  void _applyOperationProgress(
    BackupOperationProgress progress, {
    required bool isCreating,
    required bool isRestoring,
    bool isUploading = false,
  }) {
    final percent = progress.progress == null
        ? ''
        : ' (${(progress.progress! * 100).toStringAsFixed(0)}%)';
    debugPrint(
      '[BackupProgress] ${progress.message} - ${progress.detail}$percent',
    );
    emit(
      state.copyWith(
        isCreating: isCreating,
        isRestoring: isRestoring,
        isUploading: isUploading,
        operationMessage: progress.message,
        operationDetail: progress.detail,
        operationProgress: progress.progress,
        operationProcessedCount: progress.processedCount,
        operationTotalCount: progress.totalCount,
        operationEntityCount:
            progress.entityCount ?? state.operationEntityCount,
        operationFileCount: progress.fileCount ?? state.operationFileCount,
      ),
    );
    _updateLiveActivity(progress);
  }

  // Thin delegates to [BackupLiveActivityController]; call sites are unchanged.
  void _startLiveActivity({
    required String operation,
    required String provider,
    required String message,
    required String detail,
    required double progress,
  }) => _liveActivity.start(
    operation: operation,
    provider: provider,
    message: message,
    detail: detail,
    progress: progress,
  );

  void _updateLiveActivity(BackupOperationProgress progress) =>
      _liveActivity.update(progress);

  void _completeLiveActivity({
    required String message,
    required String detail,
  }) => _liveActivity.complete(message: message, detail: detail);

  void _failLiveActivity({required String message, required String detail}) =>
      _liveActivity.fail(
        message: message,
        detail: detail,
        progress: state.operationProgress ?? 0,
      );

  String _normalizeErrorMessage(Object error, {CloudProviderType? provider}) {
    final raw = '$error'.trim();
    const prefixes = <String>['Exception: ', 'Bad state: ', 'StateError: '];
    var cleaned = raw;
    for (final prefix in prefixes) {
      if (cleaned.startsWith(prefix)) {
        cleaned = cleaned.substring(prefix.length).trim();
        break;
      }
    }
    final lower = cleaned.toLowerCase();
    final providerLabel = provider?.label ?? 'cloud provider';

    if (lower.contains('401') ||
        lower.contains('unauthorized') ||
        lower.contains('expired_access_token') ||
        lower.contains('invalid_access_token')) {
      return '$providerLabel session expired. Reconnect $providerLabel, then try restoring again.';
    }
    if (lower.contains('not connected')) {
      return '$providerLabel is not connected. Reconnect it, then try restoring again.';
    }
    if (lower.contains('mirror root was not found')) {
      return 'No Credence mirror was found in $providerLabel. Upload the vault from the device that has the latest data, refresh cloud storage, then restore again.';
    }
    if (lower.contains('file not found') ||
        lower.contains('path/not_found') ||
        lower.contains('not_found')) {
      return 'A required backup file is missing in $providerLabel. Refresh cloud storage; if it is still missing, re-upload the mirror from the source device.';
    }
    if (lower.contains('snapshot is not a json object') ||
        lower.contains('format') ||
        lower.contains('json')) {
      return 'The backup metadata cannot be read. The cloud mirror may be incomplete or corrupted; re-upload it from the source device.';
    }
    if (lower.contains('hash mismatch') ||
        lower.contains('checksum') ||
        lower.contains('corrupted')) {
      return 'The backup integrity check failed. One or more files changed or uploaded incompletely; re-upload the mirror and try again.';
    }
    if (lower.contains('bad file descriptor') ||
        lower.contains('connection closed') ||
        lower.contains('connection reset')) {
      return 'Cloud download was interrupted. Keep Credence open and try restore again; files already restored will be reused.';
    }
    if (lower.contains('unsafe mirror path')) {
      return 'Restore was stopped because the backup contains an unsafe file path. Create a fresh backup from a trusted device.';
    }
    if (lower.contains('legacy encrypted cloud archives')) {
      return cleaned;
    }
    if (cleaned.isEmpty) {
      return 'Restore failed. Refresh cloud storage and try again.';
    }
    return cleaned;
  }
}
