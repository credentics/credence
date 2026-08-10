import 'dart:developer' as developer;
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:pass_doc_manager/data/vault_sync/datasources/local/vault_sync_journal_local_data_source.dart';
import 'package:pass_doc_manager/data/vault_sync/datasources/local/vault_sync_prefs_local_data_source.dart';
import 'package:pass_doc_manager/data/vault_sync/dtos/vault_sync_prefs_dto.dart';
import 'package:pass_doc_manager/data/vault_sync/mappers/vault_sync_mapper.dart';
import 'package:pass_doc_manager/data/vault_sync/mirror/dropbox_mirror_data_source.dart';
import 'package:pass_doc_manager/data/vault_sync/mirror/google_drive_mirror_data_source.dart';
import 'package:pass_doc_manager/data/vault_sync/mirror/local_folder_mirror_data_source.dart';
import 'package:pass_doc_manager/data/vault_sync/mirror/vault_mirror_import_service.dart';
import 'package:pass_doc_manager/data/vault_sync/mirror/vault_mirror_import_source.dart';
import 'package:pass_doc_manager/data/vault_sync/mirror/vault_mirror_workspace.dart';
import 'package:pass_doc_manager/data/vault_sync/mirror/vault_mirror_workspace_builder.dart';
import 'package:pass_doc_manager/data/vault_sync/services/dropbox_token_refresh_service.dart';
import 'package:pass_doc_manager/data/vault_sync/services/vault_sync_operation_builder.dart';
import 'package:pass_doc_manager/domain/vault_sync/entities/vault_sync_head_check_result_entity.dart';
import 'package:pass_doc_manager/domain/vault_sync/entities/vault_sync_head_entity.dart';
import 'package:pass_doc_manager/domain/vault_sync/entities/vault_sync_result_entity.dart';
import 'package:pass_doc_manager/domain/vault_sync/entities/vault_sync_progress_entity.dart';
import 'package:pass_doc_manager/domain/vault_sync/entities/vault_sync_settings_entity.dart';
import 'package:pass_doc_manager/domain/vault_sync/entities/vault_sync_status_entity.dart';
import 'package:pass_doc_manager/domain/vault_sync/entities/vault_sync_target_type.dart';
import 'package:pass_doc_manager/domain/vault_sync/repositories/vault_sync_repository.dart';

class VaultSyncRepositoryImpl implements VaultSyncRepository {
  const VaultSyncRepositoryImpl({
    required this.prefsLocalDataSource,
    required this.mirrorBuilder,
    required this.localMirrorDataSource,
    required this.dropboxMirrorDataSource,
    required this.googleDriveMirrorDataSource,
    required this.mirrorImportService,
    required this.syncJournalLocalDataSource,
    required this.operationBuilder,
  });

  final VaultSyncPrefsLocalDataSource prefsLocalDataSource;
  final VaultMirrorWorkspaceBuilder mirrorBuilder;
  final LocalFolderMirrorDataSource localMirrorDataSource;
  final DropboxMirrorDataSource dropboxMirrorDataSource;
  final GoogleDriveMirrorDataSource googleDriveMirrorDataSource;
  final VaultMirrorImportService mirrorImportService;
  final VaultSyncJournalLocalDataSource syncJournalLocalDataSource;
  final VaultSyncOperationBuilder operationBuilder;

  static const Duration _remoteChangeLogTimeout = Duration(seconds: 20);

  @override
  Future<VaultSyncSettingsEntity> getSettings() async {
    final prefs = await prefsLocalDataSource.readPrefs();
    return prefs.toSettingsEntity();
  }

  @override
  Future<void> saveSettings(VaultSyncSettingsEntity settings) async {
    final prefs = await prefsLocalDataSource.readPrefs();
    final next = settings.mergedInto(prefs);
    await prefsLocalDataSource.writePrefs(next);
  }

  @override
  Future<VaultSyncStatusEntity> getStatus() async {
    final prefs = await prefsLocalDataSource.readPrefs();
    return prefs.toStatusEntity();
  }

  @override
  Future<VaultSyncResultEntity> syncNow({
    VaultSyncProgressCallback? onProgress,
    bool allowDeletes = false,
  }) async {
    var prefs = await prefsLocalDataSource.readPrefs();
    prefs = await _refreshDropboxTokenIfNeeded(
      prefs,
      prefs.targetType.toTargetType(),
    );
    var settings = prefs.toSettingsEntity();

    final validation = _validateSettings(settings);
    if (validation != null) {
      return _completeWith(
        prefs: prefs,
        success: false,
        message: validation,
        uploaded: false,
        downloaded: false,
        conflictDetected: false,
      );
    }

    final deviceId = prefs.deviceId.trim().isEmpty
        ? 'device_${DateTime.now().microsecondsSinceEpoch}'
        : prefs.deviceId.trim();
    // Persist a freshly-minted deviceId immediately — BEFORE any importNow
    // branch below. Otherwise the id is regenerated on every run because the
    // import branches return without saving it, which breaks the per-device
    // op namespace (op_${deviceId}_$seq) and sequence continuity and spawns
    // duplicate device folders on the remote.
    if (prefs.deviceId.trim().isEmpty) {
      prefs = prefs.copyWith(deviceId: deviceId);
      await prefsLocalDataSource.writePrefs(prefs);
      settings = prefs.toSettingsEntity();
    }
    final revision = max(1, prefs.lastObservedRemoteRevision + 1);
    final freshLocalInstall = _hasNoSyncBaseline(prefs);

    try {
      VaultSyncHeadEntity? remoteHead;
      if (freshLocalInstall) {
        _emitProgress(
          onProgress,
          message: 'Checking remote mirror',
          detail:
              'This device has no trusted sync baseline, so the cloud mirror is checked before local upload planning.',
          progress: 0.02,
        );
        remoteHead = await _readHeadForTarget(settings);
        final preflightRemoteChecksum = remoteHead?.manifestHash.trim() ?? '';
        if (remoteHead != null &&
            remoteHead.isValid &&
            preflightRemoteChecksum.isNotEmpty) {
          _emitProgress(
            onProgress,
            message: 'Restoring remote mirror',
            detail:
                'A remote mirror exists. It must be merged into this device before any upload is allowed.',
            progress: 0.08,
          );
          return importNow(onProgress: onProgress);
        }
      }

      _emitProgress(
        onProgress,
        message: 'Calculating changes',
        detail: 'Scanning local vault content before sending only the delta.',
        progress: 0.02,
      );
      var workspace = await mirrorBuilder.build(
        deviceId: deviceId,
        revision: revision,
      );
      _emitProgress(
        onProgress,
        message: 'Calculating changes',
        detail: 'Local scan complete. Comparing against the remote manifest.',
        progress: 0.10,
        totalCount: workspace.fileCount + workspace.directoryCount + 1,
        entityCount: workspace.nodeCount,
        fileCount: workspace.fileCount,
      );
      _emitProgress(
        onProgress,
        message: 'Reading remote status',
        detail:
            'Checking the ${_providerName(settings.targetType)} head before upload planning.',
        progress: 0.11,
        totalCount: workspace.fileCount + workspace.directoryCount + 1,
        entityCount: workspace.nodeCount,
        fileCount: workspace.fileCount,
      );
      remoteHead ??= await _readHeadForTarget(settings);
      final remoteChecksum = remoteHead?.manifestHash.trim() ?? '';
      final hasExistingRemoteMirror =
          remoteHead != null && remoteHead.isValid && remoteChecksum.isNotEmpty;
      final localLooksEmpty = !_workspaceHasVaultContent(workspace);
      final localContentIndexMissing =
          (await syncJournalLocalDataSource.readContentIndex()).isEmpty;
      if (hasExistingRemoteMirror) {
        if (localLooksEmpty) {
          _emitProgress(
            onProgress,
            message: 'Restoring remote mirror',
            detail:
                'This device has no local vault content, so the cloud copy is being restored before any upload is allowed.',
            progress: 0.12,
          );
          return importNow(onProgress: onProgress);
        }

        if (remoteChecksum == workspace.contentChecksum) {
          if (localContentIndexMissing) {
            await syncJournalLocalDataSource.writeContentIndex(
              operationBuilder.contentIndexFor(workspace),
            );
            await syncJournalLocalDataSource.writeContentPayloadIndex(
              operationBuilder.contentPayloadIndexFor(workspace),
            );
          }
          return _completeWith(
            prefs: prefs,
            success: true,
            message: 'Remote mirror is already up to date.',
            uploaded: false,
            downloaded: false,
            conflictDetected: false,
            observedRemoteRevision: remoteHead.revision,
            uploadedChecksum: remoteChecksum,
            lastRemoteRevision: remoteHead.revision,
            lastRemoteChecksum: remoteChecksum,
            lastRemoteDeviceId: remoteHead.deviceId,
            deviceId: deviceId,
          );
        }

        if (localContentIndexMissing) {
          _emitProgress(
            onProgress,
            message: 'Restoring remote baseline',
            detail:
                'The local sync index is missing, so the remote mirror is merged before upload planning.',
            progress: 0.12,
          );
          return importNow(onProgress: onProgress);
        }

        final lastUploadedChecksum = prefs.lastUploadedChecksum.trim();
        if (lastUploadedChecksum.isEmpty ||
            lastUploadedChecksum != remoteChecksum) {
          _emitProgress(
            onProgress,
            message: 'Merging remote changes',
            detail:
                'Remote changes were found, so this device is importing before uploading.',
            progress: 0.12,
          );
          final importResult = await importNow(onProgress: onProgress);
          if (!importResult.success) {
            return importResult;
          }
          prefs = await prefsLocalDataSource.readPrefs();
          settings = prefs.toSettingsEntity();
          workspace = await mirrorBuilder.build(
            deviceId: deviceId,
            revision: max(1, prefs.lastObservedRemoteRevision + 1),
          );
        }
      } else if (_isCloudTarget(settings.targetType) &&
          localLooksEmpty &&
          freshLocalInstall) {
        return _completeWith(
          prefs: prefs,
          success: false,
          message:
              'Upload blocked: this device has no local vault content and no verified remote mirror was found. Restore or reconnect the cloud provider first.',
          uploaded: false,
          downloaded: false,
          conflictDetected: false,
          deviceId: deviceId,
        );
      }
      _emitProgress(
        onProgress,
        message: 'Building change plan',
        detail:
            'Comparing the local content index with the current vault mirror.',
        progress: 0.13,
        totalCount: workspace.fileCount + workspace.directoryCount + 1,
        entityCount: workspace.nodeCount,
        fileCount: workspace.fileCount,
      );
      final uploadPlan = await _prepareUploadPlan(
        deviceId: deviceId,
        workspace: workspace,
        includeDeletes: allowDeletes,
      );
      _emitProgress(
        onProgress,
        message: 'Preparing upload',
        detail: uploadPlan.operations.isEmpty
            ? 'No content changes were found. Only remote metadata may need verification.'
            : 'Prepared ${uploadPlan.operations.length} change${uploadPlan.operations.length == 1 ? '' : 's'} for upload.',
        progress: 0.15,
        totalCount: workspace.fileCount + workspace.directoryCount + 1,
        entityCount: workspace.nodeCount,
        fileCount: workspace.fileCount,
      );
      if (uploadPlan.operations.isEmpty && hasExistingRemoteMirror) {
        await _commitUploadPlan(uploadPlan);
        return _completeWith(
          prefs: prefs,
          success: true,
          message: 'Remote mirror is already up to date.',
          uploaded: false,
          downloaded: false,
          conflictDetected: false,
          observedRemoteRevision: remoteHead.revision,
          uploadedChecksum: remoteChecksum.isNotEmpty
              ? remoteChecksum
              : prefs.lastUploadedChecksum,
          lastRemoteRevision: remoteHead.revision,
          lastRemoteChecksum: remoteChecksum.isNotEmpty
              ? remoteChecksum
              : prefs.lastRemoteChecksum,
          lastRemoteDeviceId: remoteHead.deviceId,
          deviceId: deviceId,
        );
      }
      final changedFilePaths = _changedMirrorFilePaths(uploadPlan);
      final deletedFilePaths = _deletedMirrorFilePaths(uploadPlan);
      final metadataOnlyUpload = changedFilePaths.isEmpty;
      final result = switch (settings.targetType) {
        VaultSyncTargetType.localFolder =>
          await localMirrorDataSource.writeWorkspace(
            folderPath: settings.localFolderPath,
            workspace: workspace,
            metadataOnly: metadataOnlyUpload,
            allowedChangedFilePaths: changedFilePaths,
            allowedDeletedFilePaths: deletedFilePaths,
            onProgress: onProgress,
          ),
        VaultSyncTargetType.dropboxCloud =>
          await _writeDropboxWorkspaceWithProtocol(
            settings: settings,
            workspace: workspace,
            uploadPlan: uploadPlan,
            onProgress: onProgress,
          ),
        VaultSyncTargetType.googleDriveCloud =>
          await googleDriveMirrorDataSource.writeWorkspace(
            accessToken: settings.googleDriveAccessToken,
            directoryPath: settings.dropboxDirectoryPath,
            workspace: workspace,
            metadataOnly: metadataOnlyUpload,
            allowedChangedFilePaths: changedFilePaths,
            allowedDeletedFilePaths: deletedFilePaths,
            onProgress: onProgress,
          ),
        VaultSyncTargetType.none => throw StateError(
          'No sync target selected.',
        ),
      };
      await _writeHeadForTarget(settings, _headForWorkspace(workspace));
      await _commitUploadPlan(uploadPlan);

      return _completeWith(
        prefs: prefs,
        success: true,
        message:
            result.warningMessage ??
            'Mirror synchronized: ${result.fileCount} files, ${result.directoryCount} folders.',
        uploaded: true,
        downloaded: false,
        conflictDetected: false,
        observedRemoteRevision: result.revision,
        uploadedChecksum: result.checksum,
        lastRemoteRevision: result.revision,
        lastRemoteChecksum: result.checksum,
        lastRemoteDeviceId: deviceId,
        deviceId: deviceId,
      );
    } catch (error, stackTrace) {
      final message = _syncErrorMessage(error, settings.targetType);
      final failurePrefs = _prefsAfterAuthFailure(
        prefs,
        settings.targetType,
        error,
      );
      developer.log(
        '[VaultSync] Mirror sync failed: $message',
        name: 'VaultSync',
        error: error,
        stackTrace: stackTrace,
      );
      return _completeWith(
        prefs: failurePrefs,
        success: false,
        message: message,
        uploaded: false,
        downloaded: false,
        conflictDetected: false,
        deviceId: deviceId,
      );
    }
  }

  @override
  Future<VaultSyncResultEntity> importNow({
    VaultSyncProgressCallback? onProgress,
    bool replaceLocal = false,
  }) async {
    var prefs = await prefsLocalDataSource.readPrefs();
    prefs = await _refreshDropboxTokenIfNeeded(
      prefs,
      prefs.targetType.toTargetType(),
    );
    // A direct import on a fresh install must also persist a stable deviceId,
    // so a later syncNow reuses it instead of minting a new one.
    if (prefs.deviceId.trim().isEmpty) {
      prefs = prefs.copyWith(
        deviceId: 'device_${DateTime.now().microsecondsSinceEpoch}',
      );
      await prefsLocalDataSource.writePrefs(prefs);
    }
    final settings = prefs.toSettingsEntity();

    final validation = _validateSettings(settings);
    if (validation != null) {
      return _completeWith(
        prefs: prefs,
        success: false,
        message: validation,
        uploaded: false,
        downloaded: false,
        conflictDetected: false,
      );
    }

    try {
      _emitProgress(
        onProgress,
        message: 'Preparing mirror restore',
        detail: 'Opening the selected mirror source.',
        progress: 0.02,
      );
      final source = switch (settings.targetType) {
        VaultSyncTargetType.localFolder => LocalFolderVaultMirrorImportSource(
          folderPath: settings.localFolderPath,
        ),
        VaultSyncTargetType.dropboxCloud => DropboxVaultMirrorImportSource(
          dio: Dio(),
          accessToken: settings.dropboxAccessToken,
          directoryPath: settings.dropboxDirectoryPath,
        ),
        VaultSyncTargetType.googleDriveCloud =>
          GoogleDriveVaultMirrorImportSource(
            dio: Dio(),
            accessToken: settings.googleDriveAccessToken,
            directoryPath: settings.dropboxDirectoryPath,
          ),
        VaultSyncTargetType.none => throw StateError(
          'No sync target selected.',
        ),
      };
      final result = await mirrorImportService.importFromSource(
        source: source,
        mode: replaceLocal
            ? VaultMirrorImportMode.replace
            : VaultMirrorImportMode.merge,
        onProgress: onProgress,
      );
      final baselineChecksum = await _commitImportBaseline(
        result,
        replaceLocal: replaceLocal,
      );
      return _completeWith(
        prefs: prefs,
        success: true,
        message:
            result.warningMessage ??
            'Mirror restored: ${result.fileCount} files, ${result.directoryCount} folders.',
        uploaded: false,
        downloaded: true,
        conflictDetected: false,
        observedRemoteRevision: result.revision,
        uploadedChecksum: baselineChecksum,
        lastRemoteRevision: result.revision,
        lastRemoteChecksum: baselineChecksum,
      );
    } catch (error, stackTrace) {
      final message = _syncErrorMessage(error, settings.targetType);
      final failurePrefs = _prefsAfterAuthFailure(
        prefs,
        settings.targetType,
        error,
      );
      developer.log(
        '[VaultSync] Mirror restore failed: $message',
        name: 'VaultSync',
        error: error,
        stackTrace: stackTrace,
      );
      return _completeWith(
        prefs: failurePrefs,
        success: false,
        message: message,
        uploaded: false,
        downloaded: false,
        conflictDetected: false,
      );
    }
  }

  @override
  Future<VaultSyncHeadCheckResultEntity> checkRemoteHead() async {
    final startedAt = DateTime.now();
    final stopwatch = Stopwatch()..start();
    var prefs = await prefsLocalDataSource.readPrefs();
    prefs = await _refreshDropboxTokenIfNeeded(
      prefs,
      prefs.targetType.toTargetType(),
    );
    final settings = prefs.toSettingsEntity();
    final validation = _validateSettings(settings);
    if (validation != null) {
      return VaultSyncHeadCheckResultEntity(
        success: false,
        remoteAvailable: false,
        message: validation,
        providerName: _providerName(settings.targetType),
      );
    }

    try {
      final head = await _readHeadForTarget(settings);
      stopwatch.stop();
      final checkedAtIso = startedAt.toUtc().toIso8601String();
      if (head == null || !head.isValid) {
        await prefsLocalDataSource.writePrefs(
          prefs.copyWith(
            lastRemoteCheckedAtIso: checkedAtIso,
            syncBackoffFailureCount: 0,
            clearSyncBackoffUntilIso: true,
          ),
        );
        developer.log(
          '[VaultSyncPassiveCheck] ${_providerName(settings.targetType)}: '
          'no remote head found in ${stopwatch.elapsedMilliseconds}ms',
          name: 'VaultSync',
        );
        return VaultSyncHeadCheckResultEntity(
          success: true,
          remoteAvailable: false,
          message: 'No remote mirror found.',
          providerName: _providerName(settings.targetType),
          elapsedMilliseconds: stopwatch.elapsedMilliseconds,
        );
      }

      final remoteChecksum = head.manifestHash.trim();
      final localChecksum = prefs.lastUploadedChecksum.trim();
      final sameContent =
          remoteChecksum.isNotEmpty && remoteChecksum == localChecksum;
      final remoteAvailable = !sameContent;
      await prefsLocalDataSource.writePrefs(
        prefs.copyWith(
          lastRemoteCheckedAtIso: checkedAtIso,
          lastObservedRemoteRevision: sameContent
              ? max(prefs.lastObservedRemoteRevision, head.revision)
              : prefs.lastObservedRemoteRevision,
          lastUploadedChecksum: sameContent
              ? remoteChecksum
              : prefs.lastUploadedChecksum,
          lastRemoteRevision: head.revision,
          lastRemoteChecksum: remoteChecksum,
          lastRemoteDeviceId: head.deviceId,
          syncBackoffFailureCount: 0,
          clearSyncBackoffUntilIso: true,
        ),
      );
      developer.log(
        '[VaultSyncPassiveCheck] ${_providerName(settings.targetType)}: '
        'revision=${head.revision}, files=${head.fileCount}, '
        'dirs=${head.directoryCount}, available=$remoteAvailable, '
        'elapsed=${stopwatch.elapsedMilliseconds}ms',
        name: 'VaultSync',
      );
      return VaultSyncHeadCheckResultEntity(
        success: true,
        remoteAvailable: remoteAvailable,
        message: remoteAvailable
            ? 'New sync changes available.'
            : 'Remote mirror is up to date.',
        remoteHead: head,
        providerName: _providerName(settings.targetType),
        elapsedMilliseconds: stopwatch.elapsedMilliseconds,
      );
    } catch (error, stackTrace) {
      stopwatch.stop();
      final isAuthFailure = _isCloudAuthError(error);
      final failureCount = isAuthFailure
          ? 0
          : prefs.syncBackoffFailureCount + 1;
      final backoff = _backoffForFailure(failureCount);
      final backoffUntil = DateTime.now().toUtc().add(backoff);
      final message = _syncErrorMessage(error, settings.targetType);
      final failurePrefs = _prefsAfterAuthFailure(
        prefs,
        settings.targetType,
        error,
      );
      await prefsLocalDataSource.writePrefs(
        failurePrefs.copyWith(
          lastRemoteCheckedAtIso: startedAt.toUtc().toIso8601String(),
          syncBackoffFailureCount: failureCount,
          syncBackoffUntilIso: isAuthFailure
              ? null
              : backoffUntil.toIso8601String(),
          clearSyncBackoffUntilIso: isAuthFailure,
        ),
      );
      developer.log(
        '[VaultSyncPassiveCheck] ${_providerName(settings.targetType)} failed: '
        '${isAuthFailure ? '$message. Passive checks paused until reconnect.' : '$message. Backing off for ${backoff.inMinutes} min.'}',
        name: 'VaultSync',
        error: error,
        stackTrace: stackTrace,
      );
      return VaultSyncHeadCheckResultEntity(
        success: false,
        remoteAvailable: false,
        message: message,
        providerName: _providerName(settings.targetType),
        elapsedMilliseconds: stopwatch.elapsedMilliseconds,
      );
    }
  }

  @override
  Future<VaultSyncResultEntity> syncFromRemoteNow({
    VaultSyncProgressCallback? onProgress,
  }) {
    return importNow(onProgress: onProgress);
  }

  @override
  Future<VaultSyncResultEntity> syncToRemoteNow({
    VaultSyncProgressCallback? onProgress,
  }) {
    return syncNow(onProgress: onProgress);
  }

  String? _validateSettings(VaultSyncSettingsEntity settings) {
    switch (settings.targetType) {
      case VaultSyncTargetType.none:
        return 'Select a sync target first.';
      case VaultSyncTargetType.localFolder:
        if (settings.localFolderPath.trim().isEmpty) {
          return 'Local folder path is required.';
        }
      case VaultSyncTargetType.dropboxCloud:
        if (settings.dropboxAccessToken.trim().isEmpty) {
          return 'Dropbox access token is required.';
        }
      case VaultSyncTargetType.googleDriveCloud:
        if (settings.googleDriveAccessToken.trim().isEmpty) {
          return 'Google Drive access token is required.';
        }
    }

    return null;
  }

  void _emitProgress(
    VaultSyncProgressCallback? onProgress, {
    required String message,
    required String detail,
    required double progress,
    int? processedCount,
    int? totalCount,
    int? entityCount,
    int? fileCount,
  }) {
    developer.log(
      '[VaultSync] $message - $detail (${(progress * 100).toStringAsFixed(0)}%)',
      name: 'VaultSync',
    );
    onProgress?.call(
      VaultSyncProgressEntity(
        message: message,
        detail: detail,
        progress: progress.clamp(0, 1).toDouble(),
        processedCount: processedCount,
        totalCount: totalCount,
        entityCount: entityCount,
        fileCount: fileCount,
      ),
    );
  }

  VaultSyncPrefsDto _prefsAfterAuthFailure(
    VaultSyncPrefsDto prefs,
    VaultSyncTargetType targetType,
    Object error,
  ) {
    if (!_isCloudAuthError(error)) {
      return prefs;
    }
    return switch (targetType) {
      VaultSyncTargetType.dropboxCloud => prefs.copyWith(
        dropboxAccessToken: '',
        dropboxRefreshToken: '',
        dropboxAccessTokenExpiresAtIso: '',
        syncBackoffFailureCount: 0,
        clearSyncBackoffUntilIso: true,
      ),
      VaultSyncTargetType.googleDriveCloud => prefs.copyWith(
        googleDriveAccessToken: '',
        syncBackoffFailureCount: 0,
        clearSyncBackoffUntilIso: true,
      ),
      VaultSyncTargetType.localFolder || VaultSyncTargetType.none => prefs,
    };
  }

  Future<VaultSyncPrefsDto> _refreshDropboxTokenIfNeeded(
    VaultSyncPrefsDto prefs,
    VaultSyncTargetType targetType,
  ) {
    if (targetType != VaultSyncTargetType.dropboxCloud) {
      return Future.value(prefs);
    }
    return DropboxTokenRefreshService(
      prefsLocalDataSource: prefsLocalDataSource,
    ).refreshIfNeeded(prefs);
  }

  bool _isCloudAuthError(Object error) {
    if (error is DioException) {
      final statusCode = error.response?.statusCode;
      if (statusCode == 401) return true;
      if (statusCode == 403) {
        final body = '${error.response?.data ?? error.message ?? ''}'
            .toLowerCase();
        return body.contains('invalid_token') ||
            body.contains('expired') ||
            body.contains('unauthorized');
      }
    }
    final raw = '$error'.toLowerCase();
    return raw.contains('401') ||
        raw.contains('unauthorized') ||
        raw.contains('expired_access_token') ||
        raw.contains('invalid_access_token') ||
        raw.contains('invalid_token');
  }

  String _syncErrorMessage(Object error, VaultSyncTargetType targetType) {
    if (_isCloudAuthError(error)) {
      return switch (targetType) {
        VaultSyncTargetType.dropboxCloud =>
          'Dropbox session expired. Reconnect Dropbox in Backup & restore, then retry sync.',
        VaultSyncTargetType.googleDriveCloud =>
          'Google Drive session expired. Reconnect Google Drive in Backup & restore, then retry sync.',
        VaultSyncTargetType.localFolder =>
          'Local folder access failed. Choose the folder again, then retry sync.',
        VaultSyncTargetType.none =>
          'Sync provider session expired. Reconnect your provider, then retry sync.',
      };
    }
    if (error is DioException) {
      final statusCode = error.response?.statusCode;
      final provider = _providerName(targetType);
      if (statusCode != null) {
        return '$provider sync failed with HTTP $statusCode. Check the provider connection and retry.';
      }
      if (error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.receiveTimeout ||
          error.type == DioExceptionType.sendTimeout) {
        return '$provider sync timed out. Check your connection and retry.';
      }
      if (error.type == DioExceptionType.connectionError) {
        return '$provider is unreachable. Check your internet connection and retry.';
      }
    }
    final raw = '$error'.trim();
    const prefixes = <String>[
      'Exception: ',
      'Bad state: ',
      'StateError: ',
      'DioException [bad response]: ',
      'DioException [unknown]: ',
    ];
    for (final prefix in prefixes) {
      if (raw.startsWith(prefix)) {
        return raw.substring(prefix.length).trim();
      }
    }
    return raw.isEmpty
        ? 'Mirror sync failed. Check provider configuration and connectivity.'
        : raw;
  }

  Future<VaultSyncResultEntity> _completeWith({
    required VaultSyncPrefsDto prefs,
    required bool success,
    required String message,
    required bool uploaded,
    required bool downloaded,
    required bool conflictDetected,
    int? observedRemoteRevision,
    String? uploadedChecksum,
    int? lastRemoteRevision,
    String? lastRemoteChecksum,
    String? lastRemoteDeviceId,
    String? deviceId,
  }) async {
    final completedAtIso = DateTime.now().toUtc().toIso8601String();
    final next = prefs.copyWith(
      deviceId: deviceId ?? prefs.deviceId,
      lastSyncedAtIso: success ? completedAtIso : prefs.lastSyncedAtIso,
      lastRunSuccessful: success,
      lastMessage: message,
      lastObservedRemoteRevision:
          observedRemoteRevision ?? prefs.lastObservedRemoteRevision,
      lastUploadedChecksum: uploadedChecksum ?? prefs.lastUploadedChecksum,
      lastRemoteCheckedAtIso: completedAtIso,
      lastRemoteRevision: lastRemoteRevision ?? prefs.lastRemoteRevision,
      lastRemoteChecksum: lastRemoteChecksum ?? prefs.lastRemoteChecksum,
      lastRemoteDeviceId: lastRemoteDeviceId ?? prefs.lastRemoteDeviceId,
      syncBackoffFailureCount: 0,
      clearSyncBackoffUntilIso: true,
    );
    await prefsLocalDataSource.writePrefs(next);
    return buildSyncResult(
      success: success,
      message: message,
      uploaded: uploaded,
      downloaded: downloaded,
      conflictDetected: conflictDetected,
    );
  }

  VaultSyncHeadEntity _headForWorkspace(VaultMirrorWorkspace workspace) {
    return VaultSyncHeadEntity(
      revision: workspace.revision,
      deviceId: workspace.deviceId,
      manifestHash: workspace.contentChecksum,
      generatedAtIso: workspace.generatedAtIso,
      provider: 'credence',
      fileCount: workspace.fileCount,
      directoryCount: workspace.directoryCount,
    );
  }

  Future<void> _writeHeadForTarget(
    VaultSyncSettingsEntity settings,
    VaultSyncHeadEntity head,
  ) {
    final providerHead = VaultSyncHeadEntity(
      revision: head.revision,
      deviceId: head.deviceId,
      manifestHash: head.manifestHash,
      generatedAtIso: head.generatedAtIso,
      provider: _providerStorageName(settings.targetType),
      fileCount: head.fileCount,
      directoryCount: head.directoryCount,
    );
    return switch (settings.targetType) {
      VaultSyncTargetType.localFolder => localMirrorDataSource.writeHead(
        folderPath: settings.localFolderPath,
        head: providerHead,
      ),
      VaultSyncTargetType.dropboxCloud => dropboxMirrorDataSource.writeHead(
        accessToken: settings.dropboxAccessToken,
        directoryPath: settings.dropboxDirectoryPath,
        head: providerHead,
      ),
      VaultSyncTargetType.googleDriveCloud =>
        googleDriveMirrorDataSource.writeHead(
          accessToken: settings.googleDriveAccessToken,
          directoryPath: settings.dropboxDirectoryPath,
          head: providerHead,
        ),
      VaultSyncTargetType.none => Future<void>.value(),
    };
  }

  Future<VaultSyncHeadEntity?> _readHeadForTarget(
    VaultSyncSettingsEntity settings,
  ) {
    return switch (settings.targetType) {
      VaultSyncTargetType.localFolder => localMirrorDataSource.readHead(
        folderPath: settings.localFolderPath,
      ),
      VaultSyncTargetType.dropboxCloud => dropboxMirrorDataSource.readHead(
        accessToken: settings.dropboxAccessToken,
        directoryPath: settings.dropboxDirectoryPath,
      ),
      VaultSyncTargetType.googleDriveCloud =>
        googleDriveMirrorDataSource.readHead(
          accessToken: settings.googleDriveAccessToken,
          directoryPath: settings.dropboxDirectoryPath,
        ),
      VaultSyncTargetType.none => Future<VaultSyncHeadEntity?>.value(),
    };
  }

  String _providerName(VaultSyncTargetType type) {
    return switch (type) {
      VaultSyncTargetType.localFolder => 'Local folder',
      VaultSyncTargetType.dropboxCloud => 'Dropbox',
      VaultSyncTargetType.googleDriveCloud => 'Google Drive',
      VaultSyncTargetType.none => 'Sync',
    };
  }

  String _providerStorageName(VaultSyncTargetType type) {
    return switch (type) {
      VaultSyncTargetType.localFolder => 'local',
      VaultSyncTargetType.dropboxCloud => 'dropbox',
      VaultSyncTargetType.googleDriveCloud => 'google_drive',
      VaultSyncTargetType.none => 'none',
    };
  }

  bool _isCloudTarget(VaultSyncTargetType type) {
    return type == VaultSyncTargetType.dropboxCloud ||
        type == VaultSyncTargetType.googleDriveCloud;
  }

  bool _workspaceHasVaultContent(VaultMirrorWorkspace workspace) {
    return workspace.nodes.any((node) {
      final type = node.type.trim().toLowerCase();
      return type != 'profile';
    });
  }

  bool _hasNoSyncBaseline(VaultSyncPrefsDto prefs) {
    return prefs.lastUploadedChecksum.trim().isEmpty &&
        prefs.lastSyncedAtIso == null;
  }

  Duration _backoffForFailure(int failureCount) {
    if (failureCount <= 1) return const Duration(minutes: 5);
    if (failureCount == 2) return const Duration(minutes: 15);
    if (failureCount == 3) return const Duration(minutes: 30);
    return const Duration(hours: 1);
  }

  Future<VaultSyncUploadPlan> _prepareUploadPlan({
    required String deviceId,
    required VaultMirrorWorkspace workspace,
    required bool includeDeletes,
  }) async {
    final storedIndex = await syncJournalLocalDataSource.readContentIndex();
    final latestSequence = await syncJournalLocalDataSource
        .readLatestSequence();
    final plan = operationBuilder.build(
      workspace: workspace,
      previousContentIndex: storedIndex,
      deviceId: deviceId,
      latestSequence: latestSequence,
      includeDeletes: includeDeletes,
    );
    if (plan.operations.isNotEmpty) {
      await syncJournalLocalDataSource.saveLocalOperations(plan.operations);
    }
    return plan;
  }

  Future<void> _commitUploadPlan(VaultSyncUploadPlan uploadPlan) async {
    await syncJournalLocalDataSource.writeContentIndex(
      uploadPlan.nextContentIndex,
    );
    await syncJournalLocalDataSource.writeContentPayloadIndex(
      uploadPlan.nextPayloadIndex,
    );
    await syncJournalLocalDataSource.writeLatestSequence(
      uploadPlan.latestSequence,
    );
  }

  Future<String> _commitImportBaseline(
    VaultMirrorResult result, {
    bool replaceLocal = false,
  }) async {
    if (replaceLocal) {
      final prefs = await prefsLocalDataSource.readPrefs();
      final deviceId = prefs.deviceId.trim().isEmpty
          ? 'restore_baseline'
          : prefs.deviceId.trim();
      final workspace = await mirrorBuilder.build(
        deviceId: deviceId,
        revision: max(
          1,
          max(prefs.lastObservedRemoteRevision, result.revision),
        ),
      );
      await syncJournalLocalDataSource.writeContentIndex(
        operationBuilder.contentIndexFor(workspace),
      );
      await syncJournalLocalDataSource.writeContentPayloadIndex(
        operationBuilder.contentPayloadIndexFor(workspace),
      );
      await syncJournalLocalDataSource.clearLocalOperations();
      final checksum = workspace.contentChecksum.trim();
      return checksum.isEmpty ? result.checksum : checksum;
    }

    if (result.contentIndex.isNotEmpty) {
      await syncJournalLocalDataSource.writeContentIndex(result.contentIndex);
      await syncJournalLocalDataSource.writeContentPayloadIndex(
        result.contentPayloadIndex,
      );
    }
    return result.checksum;
  }

  Future<VaultMirrorResult> _writeDropboxWorkspaceWithProtocol({
    required VaultSyncSettingsEntity settings,
    required VaultMirrorWorkspace workspace,
    required VaultSyncUploadPlan uploadPlan,
    VaultSyncProgressCallback? onProgress,
  }) async {
    _emitProgress(
      onProgress,
      message: 'Reading Dropbox sync log',
      detail:
          'Checking Dropbox protocol metadata. Known operations are skipped.',
      progress: 0.155,
      totalCount: uploadPlan.nextContentIndex.length,
      fileCount: uploadPlan.nextContentIndex.keys
          .where((key) => key.startsWith('file:'))
          .length,
    );
    final protocolHead = await dropboxMirrorDataSource.readProtocolHead(
      accessToken: settings.dropboxAccessToken,
      directoryPath: settings.dropboxDirectoryPath,
    );
    final knownOperationIds = await syncJournalLocalDataSource
        .readKnownOperationIds();
    final remoteOperations = await dropboxMirrorDataSource
        .readProtocolOperations(
          accessToken: settings.dropboxAccessToken,
          directoryPath: settings.dropboxDirectoryPath,
          knownOperationIds: knownOperationIds,
        )
        .timeout(
          _remoteChangeLogTimeout,
          onTimeout: () {
            developer.log(
              '[VaultSync] Dropbox protocol operation read timed out after '
              '${_remoteChangeLogTimeout.inSeconds}s; continuing with head/checksum guard',
              name: 'VaultSync',
            );
            return const [];
          },
        );
    if (remoteOperations.isNotEmpty) {
      await syncJournalLocalDataSource.markRemoteOperationsApplied(
        remoteOperations,
      );
    }

    final publishCount = uploadPlan.operations.length >= 20
        ? 1
        : uploadPlan.operations.length;
    _emitProgress(
      onProgress,
      message: uploadPlan.operations.length >= 20
          ? 'Publishing compact change log'
          : 'Publishing change log',
      detail: uploadPlan.operations.isEmpty
          ? 'No new local operations to publish.'
          : uploadPlan.operations.length >= 20
          ? 'Bundling ${uploadPlan.operations.length} local operations into one Dropbox log entry.'
          : 'Publishing ${uploadPlan.operations.length} local operation${uploadPlan.operations.length == 1 ? '' : 's'} before file transfer.',
      progress: 0.158,
      totalCount: publishCount,
      processedCount: 0,
    );
    await dropboxMirrorDataSource.writeProtocolOperations(
      accessToken: settings.dropboxAccessToken,
      directoryPath: settings.dropboxDirectoryPath,
      operations: uploadPlan.operations,
    );
    _emitProgress(
      onProgress,
      message: 'Change log published',
      detail: uploadPlan.operations.isEmpty
          ? 'No local operation log update was needed.'
          : uploadPlan.operations.length >= 20
          ? 'Published one compact Dropbox log entry for ${uploadPlan.operations.length} local operations.'
          : 'Published ${uploadPlan.operations.length} local operation${uploadPlan.operations.length == 1 ? '' : 's'}.',
      progress: 0.16,
      totalCount: publishCount,
      processedCount: publishCount,
    );
    if (uploadPlan.operations.isNotEmpty) {
      await syncJournalLocalDataSource.markUploaded(
        uploadPlan.operations.map((operation) => operation.opId).toSet(),
      );
    }

    final result = await dropboxMirrorDataSource.writeWorkspace(
      accessToken: settings.dropboxAccessToken,
      directoryPath: settings.dropboxDirectoryPath,
      workspace: workspace,
      metadataOnly: _changedMirrorFilePaths(uploadPlan).isEmpty,
      allowedChangedFilePaths: _changedMirrorFilePaths(uploadPlan),
      allowedDeletedFilePaths: _deletedMirrorFilePaths(uploadPlan),
      onProgress: onProgress,
    );
    await dropboxMirrorDataSource.writeProtocolHead(
      accessToken: settings.dropboxAccessToken,
      directoryPath: settings.dropboxDirectoryPath,
      head: _headForWorkspace(workspace),
      expectedRev: protocolHead?.rev,
    );
    return result;
  }

  Set<String> _changedMirrorFilePaths(VaultSyncUploadPlan uploadPlan) {
    return uploadPlan.operations
        .where(
          (operation) =>
              operation.entityType == 'file' && operation.operation != 'delete',
        )
        .map((operation) => '${operation.payload['path'] ?? ''}'.trim())
        .where((path) => path.isNotEmpty)
        .toSet();
  }

  Set<String> _deletedMirrorFilePaths(VaultSyncUploadPlan uploadPlan) {
    return uploadPlan.operations
        .where(
          (operation) =>
              operation.entityType == 'file' && operation.operation == 'delete',
        )
        .map((operation) => '${operation.payload['path'] ?? ''}'.trim())
        .where((path) => path.isNotEmpty)
        .toSet();
  }
}
