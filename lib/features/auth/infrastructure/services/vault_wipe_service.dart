import 'dart:io';

import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pass_doc_manager/app/di/injection.dart';
import 'package:pass_doc_manager/data/shared/storage/encrypted_hive_box_factory.dart';
import 'package:pass_doc_manager/features/auth/infrastructure/services/app_lock_service.dart';

class VaultWipeService {
  VaultWipeService._();

  static const _preservedSupportDirectories = <String>{'local_backups'};

  static Future<void> wipeLocalVault() async {
    await AppLockService.wipeAll();
    await Hive.close();
    EncryptedHiveBoxFactory.resetAll();
    await getIt.reset();
    await Hive.deleteFromDisk();
    await _deleteApplicationSupportData();
    await configureDependencies();
  }

  static Future<void> _deleteApplicationSupportData() async {
    final directory = await getApplicationSupportDirectory();
    if (!await directory.exists()) return;

    await for (final entity in directory.list(followLinks: false)) {
      final segments = entity.uri.pathSegments
          .where((segment) => segment.isNotEmpty)
          .toList(growable: false);
      final name = segments.isEmpty ? null : segments.last;
      if (name != null && _preservedSupportDirectories.contains(name)) {
        continue;
      }
      try {
        await entity.delete(recursive: true);
      } on FileSystemException {
        // Best effort: secure storage + Hive are already wiped above.
      }
    }
  }
}
