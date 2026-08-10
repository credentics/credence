import 'dart:convert';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Manages the user's backup passphrase in platform-secure storage.
///
/// The passphrase itself is stored encrypted in Keychain/Keystore
/// (via flutter_secure_storage). Additionally, a verification hash
/// is stored so we can verify the passphrase without decrypting backups.
class BackupPassphraseService {
  static const String _passphraseKey = 'credence_backup_passphrase';
  static const String _setupCompleteKey = 'credence_backup_setup_complete';
  static const String _verifyHashKey = 'credence_backup_passphrase_hash';

  static const FlutterSecureStorage _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    // Device-bound so the master backup passphrase never rides along in an
    // iCloud/device backup or migrates to another device. Re-written under
    // this class the next time the passphrase is stored.
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  /// Returns the stored passphrase, or null if not stored.
  static Future<String?> getStoredPassphrase() async {
    return _storage.read(key: _passphraseKey);
  }

  /// Stores the passphrase in secure storage along with a verification hash.
  static Future<void> storePassphrase(String passphrase) async {
    await _storage.write(key: _passphraseKey, value: passphrase);
    await _storage.write(key: _setupCompleteKey, value: 'true');

    // Store a SHA-256 hash for verification
    final hash = await _hashPassphrase(passphrase);
    await _storage.write(key: _verifyHashKey, value: hash);
  }

  /// Removes the stored passphrase and hash.
  static Future<void> clearPassphrase() async {
    await _storage.delete(key: _passphraseKey);
    await _storage.delete(key: _verifyHashKey);
  }

  /// Returns true if the user has completed backup setup.
  static Future<bool> isSetupComplete() async {
    final value = await _storage.read(key: _setupCompleteKey);
    return value == 'true';
  }

  /// Returns true if a passphrase is stored (for auto-backup).
  static Future<bool> hasStoredPassphrase() async {
    final value = await _storage.read(key: _passphraseKey);
    return value != null && value.isNotEmpty;
  }

  /// Verifies a passphrase against the stored hash.
  ///
  /// Fails closed: if no verification hash exists, it falls back to the stored
  /// passphrase (legacy installs) and migrates a hash for next time; if nothing
  /// is stored to check against, it returns `false` rather than accepting any
  /// passphrase.
  static Future<bool> verifyPassphrase(String passphrase) async {
    final storedHash = await _storage.read(key: _verifyHashKey);
    if (storedHash == null) {
      final stored = await getStoredPassphrase();
      if (stored == null || stored.isEmpty) {
        return false;
      }
      if (!_constantTimeEquals(stored, passphrase)) {
        return false;
      }
      // Correct passphrase on a legacy install — persist a hash for next time.
      await _storage.write(
        key: _verifyHashKey,
        value: await _hashPassphrase(passphrase),
      );
      return true;
    }
    final hash = await _hashPassphrase(passphrase);
    return _constantTimeEquals(hash, storedHash);
  }

  static Future<String> _hashPassphrase(String passphrase) async {
    final sha256 = Sha256();
    final hash = await sha256.hash(utf8.encode(passphrase));
    return base64.encode(hash.bytes);
  }

  static bool _constantTimeEquals(String a, String b) {
    if (a.length != b.length) return false;
    var result = 0;
    for (var i = 0; i < a.length; i++) {
      result |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
    }
    return result == 0;
  }
}
