import 'dart:io';
import 'dart:math';

import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pass_doc_manager/data/shared/storage/encrypted_hive_box_factory.dart';
import 'package:pass_doc_manager/data/vault_sync/dtos/vault_sync_manifest_dto.dart';
import 'package:pass_doc_manager/data/vault_sync/dtos/vault_sync_prefs_dto.dart';

class VaultSyncPrefsLocalDataSource {
  VaultSyncPrefsLocalDataSource._({required Box<dynamic> box}) : _box = box;

  static const _prefsBoxName = 'credence_sync_prefs_v1';
  static const _prefsKey = 'sync_prefs_json';

  final Box<dynamic> _box;

  static Future<VaultSyncPrefsLocalDataSource> create() async {
    final box = await EncryptedHiveBoxFactory.openEncryptedBox(_prefsBoxName);
    return VaultSyncPrefsLocalDataSource._(box: box);
  }

  Future<VaultSyncPrefsDto> readPrefs() async {
    final raw = _box.get(_prefsKey);
    if (raw is! String || raw.trim().isEmpty) {
      final initial = VaultSyncPrefsDto.defaults().copyWith(
        deviceId: _generateDeviceId(),
      );
      await writePrefs(initial);
      return initial;
    }

    try {
      var parsed = VaultSyncPrefsDto.fromJsonText(raw);
      if (parsed.deviceId.trim().isEmpty) {
        parsed = parsed.copyWith(deviceId: _generateDeviceId());
        await writePrefs(parsed);
      }
      return parsed;
    } catch (_) {
      final fallback = VaultSyncPrefsDto.defaults().copyWith(
        deviceId: _generateDeviceId(),
      );
      await writePrefs(fallback);
      return fallback;
    }
  }

  Future<void> writePrefs(VaultSyncPrefsDto prefs) async {
    await _box.put(_prefsKey, prefs.toJsonText());
  }

  Future<void> storeConflictSnapshot({
    required VaultSyncManifestDto manifest,
    required List<int> encryptedPayload,
  }) async {
    final root = await _syncRootDirectory();
    final conflictDir = Directory('${root.path}/conflicts');
    if (!conflictDir.existsSync()) {
      await conflictDir.create(recursive: true);
    }

    final stamp = DateTime.now().toUtc().millisecondsSinceEpoch;
    final base = 'remote_conflict_r${manifest.revision}_$stamp';
    final manifestFile = File('${conflictDir.path}/$base.manifest.json');
    final payloadFile = File('${conflictDir.path}/$base.snapshot.enc');

    await manifestFile.writeAsString(manifest.toJsonText(), flush: true);
    await payloadFile.writeAsBytes(encryptedPayload, flush: true);
  }

  Future<Directory> _syncRootDirectory() async {
    final appSupport = await getApplicationSupportDirectory();
    final dir = Directory('${appSupport.path}/vault_sync');
    if (!dir.existsSync()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  String _generateDeviceId() {
    final random = Random.secure();
    final bytes = List<int>.generate(8, (_) => random.nextInt(256));
    final hex = bytes.map((it) => it.toRadixString(16).padLeft(2, '0')).join();
    final ts = DateTime.now().toUtc().millisecondsSinceEpoch.toRadixString(16);
    return 'device_$ts$hex';
  }
}
