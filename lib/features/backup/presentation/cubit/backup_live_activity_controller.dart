import 'dart:async';

import 'package:pass_doc_manager/app/platform/live_activity_service.dart';
import 'package:pass_doc_manager/features/backup/domain/entities/backup_operation_progress.dart';

/// Owns the iOS Live Activity lifecycle for a backup/sync operation.
///
/// Extracted from `BackupCubit` so the cubit no longer tracks the live-activity
/// operation/provider or talks to [LiveActivityService] directly. This holds no
/// cubit state — callers pass in the progress value where one is needed.
class BackupLiveActivityController {
  String? _operation;
  String? _provider;

  void start({
    required String operation,
    required String provider,
    required String message,
    required String detail,
    required double progress,
  }) {
    _operation = operation;
    _provider = provider;
    unawaited(
      LiveActivityService.start(
        operation: operation,
        provider: provider,
        message: message,
        detail: detail,
        progress: progress,
      ),
    );
  }

  void update(BackupOperationProgress progress) {
    final operation = _operation;
    final provider = _provider;
    if (operation == null || provider == null) {
      return;
    }
    unawaited(
      LiveActivityService.update(
        operation: operation,
        provider: provider,
        message: progress.message,
        detail: progress.detail,
        progress: progress.progress ?? 0,
      ),
    );
  }

  void complete({required String message, required String detail}) {
    final operation = _operation;
    final provider = _provider;
    if (operation == null || provider == null) {
      return;
    }
    unawaited(
      LiveActivityService.complete(
        operation: operation,
        provider: provider,
        message: message,
        detail: detail,
      ),
    );
    _operation = null;
    _provider = null;
  }

  void fail({
    required String message,
    required String detail,
    required double progress,
  }) {
    final operation = _operation;
    final provider = _provider;
    if (operation == null || provider == null) {
      return;
    }
    unawaited(
      LiveActivityService.fail(
        operation: operation,
        provider: provider,
        message: message,
        detail: detail,
        progress: progress,
      ),
    );
    _operation = null;
    _provider = null;
  }
}
