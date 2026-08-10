import 'dart:async';
import 'dart:developer' as developer;
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:pass_doc_manager/app/sync/vault_data_refresh_signal.dart';
import 'package:pass_doc_manager/domain/vault_sync/entities/vault_sync_head_entity.dart';
import 'package:pass_doc_manager/domain/vault_sync/entities/vault_sync_progress_entity.dart';
import 'package:pass_doc_manager/domain/vault_sync/entities/vault_sync_settings_entity.dart';
import 'package:pass_doc_manager/domain/vault_sync/entities/vault_sync_status_entity.dart';
import 'package:pass_doc_manager/domain/vault_sync/entities/vault_sync_target_type.dart';
import 'package:pass_doc_manager/domain/vault_sync/repositories/vault_sync_repository.dart';

enum VaultSyncCoordinatorState {
  idle,
  checking,
  remoteAvailable,
  syncing,
  success,
  error,
  paused,
}

class VaultSyncCoordinator extends ChangeNotifier {
  VaultSyncCoordinator({
    required VaultSyncRepository repository,
    Random? random,
  }) : _repository = repository,
       _random = random ?? Random();

  final VaultSyncRepository _repository;
  final Random _random;

  Timer? _pollTimer;
  Timer? _hideTimer;
  bool _started = false;
  bool _operationRunning = false;

  VaultSyncCoordinatorState _state = VaultSyncCoordinatorState.idle;
  String _message = '';
  String _detail = '';
  double? _progress;
  VaultSyncHeadEntity? _remoteHead;
  String? _providerName;
  DateTime? _lastCheckedAt;

  VaultSyncCoordinatorState get state => _state;
  String get message => _message;
  String get detail => _detail;
  double? get progress => _progress;
  VaultSyncHeadEntity? get remoteHead => _remoteHead;
  String? get providerName => _providerName;
  DateTime? get lastCheckedAt => _lastCheckedAt;
  bool get hasRemoteChanges =>
      _state == VaultSyncCoordinatorState.remoteAvailable;
  bool get isBusy =>
      _state == VaultSyncCoordinatorState.checking ||
      _state == VaultSyncCoordinatorState.syncing;

  void start() {
    if (_started) return;
    _started = true;
    _scheduleNextCheck(initial: true);
  }

  void stop() {
    _started = false;
    _pollTimer?.cancel();
    _pollTimer = null;
    _hideTimer?.cancel();
    _hideTimer = null;
  }

  Future<void> handleAppResumed() async {
    if (!_started) start();
    final settings = await _repository.getSettings();
    if (!settings.remoteCheckOnResume) {
      _scheduleNextCheck();
      return;
    }
    await checkNow(reason: 'resume');
  }

  Future<void> checkNow({bool force = false, String reason = 'manual'}) async {
    if (_operationRunning) return;

    final settings = await _repository.getSettings();
    final provider = _providerLabel(settings.targetType);
    if (!_canCheckTarget(settings)) {
      _setState(
        VaultSyncCoordinatorState.paused,
        message: 'Sync checks paused',
        detail: 'Choose and configure a sync provider to enable checks.',
        providerName: provider,
      );
      return;
    }

    final status = await _repository.getStatus();
    final now = DateTime.now().toUtc();
    if (!force && !_isIntervalDue(settings, status, now)) {
      _scheduleNextCheck();
      return;
    }

    final backoffUntil = _parseIso(status.syncBackoffUntilIso);
    if (!force && backoffUntil != null && backoffUntil.isAfter(now)) {
      _setState(
        VaultSyncCoordinatorState.paused,
        message: 'Sync check paused',
        detail: 'Retrying after ${_formatRelative(backoffUntil)}.',
        providerName: provider,
      );
      _scheduleAt(backoffUntil.difference(now));
      return;
    }

    _operationRunning = true;
    _setState(
      VaultSyncCoordinatorState.checking,
      message: 'Checking $provider',
      detail: 'Reading only the mirror head.json.',
      progress: 0.2,
      providerName: provider,
    );

    try {
      final result = await _repository.checkRemoteHead();
      _lastCheckedAt = DateTime.now();
      if (result.success && result.remoteAvailable) {
        _setState(
          VaultSyncCoordinatorState.remoteAvailable,
          message: 'New sync changes available',
          detail: _remoteChangeDetail(result.remoteHead, provider),
          progress: 1,
          remoteHead: result.remoteHead,
          providerName: result.providerName ?? provider,
        );
      } else if (result.success) {
        _setState(
          VaultSyncCoordinatorState.success,
          message: 'Sync check complete',
          detail: result.message,
          progress: 1,
          remoteHead: result.remoteHead,
          providerName: result.providerName ?? provider,
        );
        _hideSuccessSoon();
      } else {
        _setState(
          VaultSyncCoordinatorState.error,
          message: 'Sync check failed',
          detail: result.message,
          progress: null,
          providerName: result.providerName ?? provider,
        );
      }
      developer.log(
        '[VaultSyncCoordinator] check=$reason provider=$provider '
        'success=${result.success} remote=${result.remoteAvailable} '
        'bytes=${result.bytesRead} elapsed=${result.elapsedMilliseconds}ms',
        name: 'VaultSync',
      );
    } catch (error, stackTrace) {
      _setState(
        VaultSyncCoordinatorState.error,
        message: 'Sync check failed',
        detail: _cleanError(error),
        providerName: provider,
      );
      developer.log(
        '[VaultSyncCoordinator] passive check crashed',
        name: 'VaultSync',
        error: error,
        stackTrace: stackTrace,
      );
    } finally {
      _operationRunning = false;
      _scheduleNextCheck();
    }
  }

  Future<void> syncFromRemoteNow() async {
    if (_operationRunning) return;

    final settings = await _repository.getSettings();
    final provider = _providerLabel(settings.targetType);
    if (!_canCheckTarget(settings)) {
      _setState(
        VaultSyncCoordinatorState.error,
        message: 'Restore unavailable',
        detail: 'Choose and configure a sync provider first.',
        providerName: provider,
      );
      return;
    }

    _operationRunning = true;
    _setState(
      VaultSyncCoordinatorState.syncing,
      message: 'Restoring from $provider',
      detail: 'Downloading mirror files after your confirmation.',
      progress: 0.02,
      providerName: provider,
    );

    try {
      final result = await _repository.syncFromRemoteNow(
        onProgress: _handleProgress,
      );
      if (result.success) {
        VaultDataRefreshSignal.notifyRestoreCompleted();
        _setState(
          VaultSyncCoordinatorState.success,
          message: 'Restore complete',
          detail: result.message,
          progress: 1,
          providerName: provider,
          remoteHead: _remoteHead,
        );
        _hideSuccessSoon();
      } else {
        _setState(
          VaultSyncCoordinatorState.error,
          message: 'Restore failed',
          detail: result.message,
          providerName: provider,
        );
      }
    } catch (error, stackTrace) {
      _setState(
        VaultSyncCoordinatorState.error,
        message: 'Restore failed',
        detail: _cleanError(error),
        providerName: provider,
      );
      developer.log(
        '[VaultSyncCoordinator] restore failed',
        name: 'VaultSync',
        error: error,
        stackTrace: stackTrace,
      );
    } finally {
      _operationRunning = false;
      _scheduleNextCheck();
    }
  }

  Future<void> syncToRemoteNow() async {
    if (_operationRunning) return;

    final settings = await _repository.getSettings();
    final provider = _providerLabel(settings.targetType);
    if (!_canCheckTarget(settings)) {
      _setState(
        VaultSyncCoordinatorState.error,
        message: 'Backup unavailable',
        detail: 'Choose and configure a sync provider first.',
        providerName: provider,
      );
      return;
    }

    _operationRunning = true;
    _setState(
      VaultSyncCoordinatorState.syncing,
      message: 'Uploading to $provider',
      detail: 'Writing folders, files, metadata, manifest, and head.',
      progress: 0.02,
      providerName: provider,
    );

    try {
      final result = await _repository.syncToRemoteNow(
        onProgress: _handleProgress,
      );
      if (result.success) {
        _setState(
          VaultSyncCoordinatorState.success,
          message: 'Backup complete',
          detail: result.message,
          progress: 1,
          providerName: provider,
        );
        _hideSuccessSoon();
      } else {
        _setState(
          VaultSyncCoordinatorState.error,
          message: 'Backup failed',
          detail: result.message,
          providerName: provider,
        );
      }
    } catch (error, stackTrace) {
      _setState(
        VaultSyncCoordinatorState.error,
        message: 'Backup failed',
        detail: _cleanError(error),
        providerName: provider,
      );
      developer.log(
        '[VaultSyncCoordinator] upload failed',
        name: 'VaultSync',
        error: error,
        stackTrace: stackTrace,
      );
    } finally {
      _operationRunning = false;
      _scheduleNextCheck();
    }
  }

  void _handleProgress(VaultSyncProgressEntity progress) {
    _setState(
      VaultSyncCoordinatorState.syncing,
      message: progress.message,
      detail: progress.detail,
      progress: progress.progress,
      providerName: _providerName,
      remoteHead: _remoteHead,
    );
  }

  bool _canCheckTarget(VaultSyncSettingsEntity settings) {
    return switch (settings.targetType) {
      VaultSyncTargetType.localFolder =>
        settings.localFolderPath.trim().isNotEmpty,
      VaultSyncTargetType.dropboxCloud =>
        settings.dropboxAccessToken.trim().isNotEmpty,
      VaultSyncTargetType.googleDriveCloud =>
        settings.googleDriveAccessToken.trim().isNotEmpty,
      VaultSyncTargetType.none => false,
    };
  }

  bool _isIntervalDue(
    VaultSyncSettingsEntity settings,
    VaultSyncStatusEntity status,
    DateTime now,
  ) {
    final intervalMinutes = settings.remoteCheckIntervalMinutes;
    if (intervalMinutes <= 0) return false;
    final checkedAt = _parseIso(status.lastRemoteCheckedAtIso);
    if (checkedAt == null) return true;
    final nextAllowed = checkedAt.add(Duration(minutes: intervalMinutes));
    return !nextAllowed.isAfter(now);
  }

  void _scheduleNextCheck({bool initial = false}) {
    _pollTimer?.cancel();
    if (!_started) return;
    _repository.getSettings().then((settings) {
      if (!_started || settings.remoteCheckIntervalMinutes <= 0) return;
      if (!_canCheckTarget(settings)) return;
      final interval = initial
          ? Duration(seconds: 2 + _random.nextInt(4))
          : Duration(minutes: settings.remoteCheckIntervalMinutes) + _jitter();
      _pollTimer = Timer(interval, () => checkNow(reason: 'timer'));
    });
  }

  void _scheduleAt(Duration delay) {
    _pollTimer?.cancel();
    if (!_started) return;
    _pollTimer = Timer(delay + _jitter(), () => checkNow(reason: 'backoff'));
  }

  Duration _jitter() => Duration(seconds: 10 + _random.nextInt(21));

  void _setState(
    VaultSyncCoordinatorState state, {
    required String message,
    String detail = '',
    double? progress,
    VaultSyncHeadEntity? remoteHead,
    String? providerName,
  }) {
    _hideTimer?.cancel();
    _state = state;
    _message = message;
    _detail = detail;
    _progress = progress;
    _remoteHead = remoteHead;
    _providerName = providerName;
    notifyListeners();
  }

  void _hideSuccessSoon() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 5), () {
      if (_state == VaultSyncCoordinatorState.success) {
        _setState(VaultSyncCoordinatorState.idle, message: '');
      }
    });
  }

  DateTime? _parseIso(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    return DateTime.tryParse(value)?.toUtc();
  }

  String _providerLabel(VaultSyncTargetType type) {
    return switch (type) {
      VaultSyncTargetType.localFolder => 'Local folder',
      VaultSyncTargetType.dropboxCloud => 'Dropbox',
      VaultSyncTargetType.googleDriveCloud => 'Google Drive',
      VaultSyncTargetType.none => 'Sync',
    };
  }

  String _remoteChangeDetail(VaultSyncHeadEntity? head, String provider) {
    if (head == null) return '$provider has a newer mirror.';
    final source = head.deviceId.trim().isEmpty
        ? 'another device'
        : head.deviceId;
    final generated = DateTime.tryParse(head.generatedAtIso)?.toLocal();
    final time = generated == null
        ? 'recently'
        : '${generated.month}/${generated.day} ${generated.hour.toString().padLeft(2, '0')}:${generated.minute.toString().padLeft(2, '0')}';
    return '$provider · $time · $source';
  }

  String _formatRelative(DateTime until) {
    final minutes = until.difference(DateTime.now().toUtc()).inMinutes;
    if (minutes <= 1) return 'about 1 minute';
    if (minutes < 60) return '$minutes minutes';
    return '${(minutes / 60).ceil()} hour';
  }

  String _cleanError(Object error) {
    final raw = '$error'.trim();
    for (final prefix in const ['Exception: ', 'Bad state: ', 'StateError: ']) {
      if (raw.startsWith(prefix)) return raw.substring(prefix.length).trim();
    }
    return raw.isEmpty ? 'Sync failed. Check provider configuration.' : raw;
  }
}
