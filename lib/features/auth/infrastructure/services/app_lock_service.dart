import 'dart:convert';
import 'dart:isolate';
import 'dart:math';

import 'package:cryptography/cryptography.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';

/// Manages PIN code and biometric authentication for the vault.
///
/// PIN is stored as an Argon2id hash (with a random per-PIN salt) in secure
/// storage (Keychain/Keystore). Legacy SHA-256 hashes are still verified and
/// transparently upgraded on the next successful unlock. Biometric auth
/// delegates to the platform via `local_auth`.
class AppLockService {
  static const _pinHashKey = 'credence_pin_hash';
  static const _pinSaltKey = 'credence_pin_salt';
  static const _biometricEnabledKey = 'credence_biometric_enabled';
  static const _lockTimeoutKey = 'credence_lock_timeout_seconds';
  static const _failedAttemptsKey = 'credence_failed_attempts';
  static const _lockoutUntilKey = 'credence_lockout_until';
  static const _revealAuthRequiredKey = 'credence_reveal_auth_required';
  static const _lastUnlockedAtKey = 'credence_last_unlocked_at';
  static const _lockWhenLeavingKey = 'credence_lock_when_leaving';
  static const _wipeAfterFiveAttemptsKey = 'credence_wipe_after_five_attempts';

  static const FlutterSecureStorage _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    // `first_unlock_this_device` keeps the PIN hash/salt off iCloud + device
    // backups and prevents it migrating to another device. The hash is
    // re-written under this stricter class on the next successful unlock
    // (Argon2id upgrade) or the next setPin.
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  static final LocalAuthentication _localAuth = LocalAuthentication();
  static final ValueNotifier<int> lockRequests = ValueNotifier<int>(0);

  /// Requests the root app gate to return to the lock screen.
  static void requestLock() {
    lockRequests.value++;
  }

  // ── PIN ──

  /// Returns true if a PIN has been set up.
  static Future<bool> isPinConfigured() async {
    final hash = await _storage.read(key: _pinHashKey);
    return hash != null && hash.isNotEmpty;
  }

  /// Sets up a new PIN, hashed with Argon2id and a fresh random salt.
  static Future<void> setPin(String pin) async {
    final salt = _randomBytes(16);
    final hash = await _hashPinArgon2(pin, salt);
    await _storage.write(key: _pinSaltKey, value: base64.encode(salt));
    await _storage.write(key: _pinHashKey, value: '$_pinKdfPrefix$hash');
  }

  /// Verifies the given PIN against the stored hash.
  ///
  /// Handles both the current Argon2id format and legacy single-pass SHA-256
  /// hashes; on a successful legacy verification the PIN is transparently
  /// re-hashed with Argon2id so the weak hash is retired.
  static Future<bool> verifyPin(String pin) async {
    final storedHash = await _storage.read(key: _pinHashKey);
    final salt = await _storage.read(key: _pinSaltKey);
    if (storedHash == null || salt == null) return false;

    if (storedHash.startsWith(_pinKdfPrefix)) {
      final saltBytes = base64.decode(salt);
      final computed = '$_pinKdfPrefix${await _hashPinArgon2(pin, saltBytes)}';
      return _constantTimeEquals(computed, storedHash);
    }

    // Legacy SHA-256 hash with a timestamp salt.
    final legacy = await _hashPinLegacy(pin, salt);
    if (!_constantTimeEquals(legacy, storedHash)) {
      return false;
    }
    // Upgrade in place to Argon2id now that we know the PIN is correct.
    await setPin(pin);
    return true;
  }

  /// Removes the stored PIN.
  static Future<void> clearPin() async {
    await _storage.delete(key: _pinHashKey);
    await _storage.delete(key: _pinSaltKey);
  }

  // ── Biometrics ──

  /// Returns true if the device supports biometric authentication.
  static Future<bool> isBiometricAvailable() async {
    try {
      final canCheck = await _localAuth.canCheckBiometrics;
      final isSupported = await _localAuth.isDeviceSupported();
      return canCheck || isSupported;
    } catch (_) {
      return false;
    }
  }

  /// Returns the available biometric types.
  static Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } catch (_) {
      return const [];
    }
  }

  /// Returns true if biometric unlock is enabled by the user.
  static Future<bool> isBiometricEnabled() async {
    final value = await _storage.read(key: _biometricEnabledKey);
    return value == 'true';
  }

  /// Enables or disables biometric unlock.
  static Future<void> setBiometricEnabled(bool enabled) async {
    await _storage.write(
      key: _biometricEnabledKey,
      value: enabled ? 'true' : 'false',
    );
  }

  /// Attempts biometric authentication.
  static Future<bool> authenticateWithBiometrics({
    String reason = 'Unlock your vault',
  }) async {
    try {
      return await _localAuth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );
    } catch (_) {
      return false;
    }
  }

  // ── Reveal Auth ──

  /// Returns true if PIN/biometric is required before revealing a password.
  /// Defaults to true (secure default).
  static Future<bool> isRevealAuthRequired() async {
    final value = await _storage.read(key: _revealAuthRequiredKey);
    return value != 'false';
  }

  /// Enables or disables the reveal-auth requirement.
  static Future<void> setRevealAuthRequired(bool required) async {
    await _storage.write(
      key: _revealAuthRequiredKey,
      value: required ? 'true' : 'false',
    );
  }

  // ── Lock Timeout ──

  /// Returns the lock timeout in seconds. 0 = immediate, -1 = never.
  static Future<int> getLockTimeout() async {
    final value = await _storage.read(key: _lockTimeoutKey);
    if (value == null) return 30; // Default: 30 seconds
    return int.tryParse(value) ?? 0;
  }

  /// Sets the lock timeout in seconds.
  static Future<void> setLockTimeout(int seconds) async {
    await _storage.write(key: _lockTimeoutKey, value: '$seconds');
  }

  /// Returns true when the vault should lock whenever the app is left.
  /// Defaults to true for a secure local-first vault.
  static Future<bool> isLockWhenLeavingEnabled() async {
    final value = await _storage.read(key: _lockWhenLeavingKey);
    return value != 'false';
  }

  static Future<void> setLockWhenLeavingEnabled(bool enabled) async {
    await _storage.write(
      key: _lockWhenLeavingKey,
      value: enabled ? 'true' : 'false',
    );
  }

  // ── Wipe ──

  /// Destroys all vault data — PIN, passphrase, preferences, everything.
  static Future<void> wipeAll() async {
    await _storage.deleteAll();
  }

  /// Returns true when five wrong PIN attempts should wipe the local vault.
  /// Defaults to false, so wrong attempts soft-lock unless explicitly changed.
  static Future<bool> isWipeAfterFiveAttemptsEnabled() async {
    final value = await _storage.read(key: _wipeAfterFiveAttemptsKey);
    return value == 'true';
  }

  static Future<void> setWipeAfterFiveAttemptsEnabled(bool enabled) async {
    await _storage.write(
      key: _wipeAfterFiveAttemptsKey,
      value: enabled ? 'true' : 'false',
    );
  }

  // ── Brute-Force Protection ──

  /// Lockout durations by attempt threshold (attempts → seconds).
  static const Map<int, int> _lockoutThresholds = {
    15: 1800, // 30 minutes
    10: 300, //  5 minutes
    5: 30, //   30 seconds
  };

  /// Returns the current number of consecutive failed PIN attempts.
  static Future<int> get failedAttemptCount async {
    final value = await _storage.read(key: _failedAttemptsKey);
    return int.tryParse(value ?? '') ?? 0;
  }

  /// Returns `true` when the user is currently locked out.
  static Future<bool> isLockedOut() async {
    final remaining = await lockoutRemainingSeconds();
    return remaining > 0;
  }

  /// Returns the number of seconds remaining in the current lockout,
  /// or `0` if there is no active lockout.
  static Future<int> lockoutRemainingSeconds() async {
    final raw = await _storage.read(key: _lockoutUntilKey);
    if (raw == null) return 0;
    final until = DateTime.tryParse(raw);
    if (until == null) return 0;
    final diff = until.difference(DateTime.now()).inSeconds;
    return diff > 0 ? diff : 0;
  }

  /// Records a failed PIN attempt and applies a lockout if a threshold is
  /// reached.  Returns the new total number of failed attempts.
  static Future<int> recordFailedAttempt() async {
    final current = await failedAttemptCount;
    final updated = current + 1;
    await _storage.write(key: _failedAttemptsKey, value: '$updated');

    // Check thresholds from highest to lowest.
    for (final entry in _lockoutThresholds.entries) {
      if (updated >= entry.key) {
        final until = DateTime.now().add(Duration(seconds: entry.value));
        await _storage.write(
          key: _lockoutUntilKey,
          value: until.toIso8601String(),
        );
        break;
      }
    }

    return updated;
  }

  /// Resets the failed-attempt counter and clears any active lockout.
  /// Call this after a successful PIN or biometric unlock.
  static Future<void> resetAttempts() async {
    await _storage.delete(key: _failedAttemptsKey);
    await _storage.delete(key: _lockoutUntilKey);
  }

  /// Records a successful unlock and clears brute-force state.
  static Future<void> recordSuccessfulUnlock() async {
    await resetAttempts();
    await _storage.write(
      key: _lastUnlockedAtKey,
      value: DateTime.now().toIso8601String(),
    );
  }

  /// Returns the last successful unlock time for the local trust cue.
  static Future<DateTime?> lastUnlockedAt() async {
    final raw = await _storage.read(key: _lastUnlockedAtKey);
    if (raw == null || raw.isEmpty) return null;
    return DateTime.tryParse(raw);
  }

  // ── Helpers ──

  /// Prefix marking an Argon2id-format stored hash. Legacy SHA-256 hashes
  /// have no prefix (bare base64), which is how [verifyPin] tells them apart.
  static const _pinKdfPrefix = 'argon2id:';

  /// Hashes [pin] with Argon2id using [salt]. Argon2id is deliberately
  /// CPU+memory heavy, so it runs on a worker isolate to keep the unlock
  /// screen responsive.
  static Future<String> _hashPinArgon2(String pin, List<int> salt) {
    return Isolate.run(() async {
      final argon2id = Argon2id(
        memory: 19456, // ~19 MB — OWASP recommended minimum
        iterations: 3,
        parallelism: 1,
        hashLength: 32,
      );
      final key = await argon2id.deriveKey(
        secretKey: SecretKey(utf8.encode(pin)),
        nonce: salt,
      );
      final bytes = await key.extractBytes();
      return base64.encode(bytes);
    });
  }

  /// Legacy single-pass SHA-256 hash (kept only to verify + upgrade old PINs).
  static Future<String> _hashPinLegacy(String pin, String salt) async {
    final sha256 = Sha256();
    final hash = await sha256.hash(utf8.encode('$salt:$pin'));
    return base64.encode(hash.bytes);
  }

  static Uint8List _randomBytes(int length) {
    final random = Random.secure();
    return Uint8List.fromList(
      List<int>.generate(length, (_) => random.nextInt(256)),
    );
  }

  /// Length-independent-leaking but value-constant-time string comparison,
  /// to avoid leaking hash bytes through comparison timing.
  static bool _constantTimeEquals(String a, String b) {
    if (a.length != b.length) return false;
    var result = 0;
    for (var i = 0; i < a.length; i++) {
      result |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
    }
    return result == 0;
  }
}
