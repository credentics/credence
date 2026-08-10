import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:pass_doc_manager/data/shared/storage/hive_migration_runner.dart';

class EncryptedHiveBoxFactory {
  EncryptedHiveBoxFactory._();

  static const _encryptionKeyStorageKey = 'credence_encryption_key_v1';
  static const _keyLengthBytes = 32;

  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  static Future<void>? _hiveInitialization;
  static Uint8List? _cachedKey;
  // Single-flight guard for key load/creation. Without it, concurrent first
  // box opens (fresh keychain) each generate a key and race to write it —
  // iOS rejects the second add with errSecDuplicateItem (-25299), and worse,
  // boxes could be encrypted under different keys.
  static Future<Uint8List>? _keyFuture;
  static final Map<String, Future<Box<dynamic>>> _boxFutures = {};

  /// Clears the cached encryption key from memory.
  /// Call this when the app goes to background to reduce exposure.
  static void clearCachedKey() {
    if (_cachedKey != null) {
      // Overwrite with zeros before nulling
      for (var i = 0; i < _cachedKey!.length; i++) {
        _cachedKey![i] = 0;
      }
      _cachedKey = null;
    }
  }

  /// Resets all cached state so boxes will be reopened fresh.
  /// Call this before [Hive.deleteFromDisk] during vault wipe.
  static void resetAll() {
    clearCachedKey();
    _keyFuture = null;
    _boxFutures.clear();
    _hiveInitialization = null;
  }

  static Future<Box<dynamic>> openEncryptedBox(String boxName) {
    return _boxFutures.putIfAbsent(boxName, () async {
      await _ensureHiveInitialized();
      final encryptionKey = await _loadOrCreateEncryptionKey();
      final box = await Hive.openBox<dynamic>(
        boxName,
        encryptionCipher: HiveAesCipher(encryptionKey),
      );
      await HiveMigrationRunner.runMigrations(boxName, box);
      return box;
    });
  }

  static Future<void> _ensureHiveInitialized() {
    return _hiveInitialization ??= Hive.initFlutter();
  }

  static Future<Uint8List> _loadOrCreateEncryptionKey() {
    final cached = _cachedKey;
    if (cached != null) {
      return Future.value(cached);
    }
    // Single-flight: concurrent first-time callers all await one load/create,
    // so the key is generated and written exactly once (no -25299 race).
    return _keyFuture ??= _loadOrCreateEncryptionKeyOnce();
  }

  static Future<Uint8List> _loadOrCreateEncryptionKeyOnce() async {
    final storedKey = await _secureStorage.read(key: _encryptionKeyStorageKey);
    if (storedKey != null && storedKey.isNotEmpty) {
      try {
        final decoded = base64Decode(storedKey);
        if (decoded.length == _keyLengthBytes) {
          final key = Uint8List.fromList(decoded);
          _cachedKey = key;
          return key;
        }
      } catch (_) {
        // Regenerate if secure storage value is corrupted.
      }
      await _secureStorage.delete(key: _encryptionKeyStorageKey);
    }

    final random = Random.secure();
    final generated = Uint8List.fromList(
      List<int>.generate(_keyLengthBytes, (_) => random.nextInt(256)),
    );
    await _secureStorage.write(
      key: _encryptionKeyStorageKey,
      value: base64Encode(generated),
    );
    _cachedKey = generated;
    return generated;
  }
}
