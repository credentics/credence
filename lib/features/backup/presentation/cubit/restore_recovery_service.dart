import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// Detects and clears the leftover `restore_rollback` directory a previous,
/// interrupted restore may have left on disk. Extracted from `BackupCubit` so
/// the filesystem logic is isolated and testable; the cubit keeps the state
/// emission around it.
class RestoreRecoveryService {
  static const String _rollbackDirName = 'restore_rollback';

  Future<Directory> _rollbackDirectory() async {
    final supportDir = await getApplicationSupportDirectory();
    return Directory(
      '${supportDir.path}${Platform.pathSeparator}$_rollbackDirName',
    );
  }

  /// True when a rollback directory is present, i.e. a restore did not finish.
  Future<bool> hasInterruptedRestore() async {
    try {
      return (await _rollbackDirectory()).existsSync();
    } catch (_) {
      return false;
    }
  }

  /// Removes the rollback directory (accepting the restore / discarding the
  /// ability to roll back). Throws if deletion fails.
  Future<void> discardRollback() async {
    final dir = await _rollbackDirectory();
    if (await dir.exists()) {
      await dir.delete(recursive: true);
    }
  }
}
