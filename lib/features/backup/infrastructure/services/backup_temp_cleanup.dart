import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// Cleans up orphaned staging/temp files from interrupted backups or restores.
class BackupTempCleanup {
  /// Run on app launch to clean up any leftover temp files.
  static Future<void> run() async {
    try {
      final supportDir = await getApplicationSupportDirectory();

      // Clean staging files
      final stagingDir = Directory('${supportDir.path}${Platform.pathSeparator}restore_staging');
      if (await stagingDir.exists()) {
        debugPrint('[Cleanup] Removing orphaned staging directory');
        await stagingDir.delete(recursive: true);
      }

      // Clean rollback copies (if restore succeeded, these should already be deleted)
      final rollbackDir = Directory('${supportDir.path}${Platform.pathSeparator}restore_rollback');
      if (await rollbackDir.exists()) {
        debugPrint('[Cleanup] Removing orphaned rollback directory');
        await rollbackDir.delete(recursive: true);
      }

      // Clean temp decrypt files
      final tempDir = Directory('${supportDir.path}${Platform.pathSeparator}backup_temp');
      if (await tempDir.exists()) {
        debugPrint('[Cleanup] Removing orphaned backup temp directory');
        await tempDir.delete(recursive: true);
      }
    } catch (e) {
      debugPrint('[Cleanup] Error during temp cleanup: $e');
    }
  }
}
