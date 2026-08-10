import 'dart:convert';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:pass_doc_manager/data/vault_portability/dtos/vault_snapshot_dto.dart';

/// Encodes/decodes vault snapshots using AES-256-GCM with Argon2id KDF.
///
/// Binary format: [32-byte salt][12-byte nonce][ciphertext+MAC]
class VaultSnapshotCodec {
  Future<List<int>> encode({
    required VaultSnapshotDto snapshot,
    required String passphrase,
  }) async {
    _validatePassphrase(passphrase);

    final envelope = {
      'magic': _magic,
      'version': 2,
      'snapshot': snapshot.toMap(),
    };

    final plaintext = Uint8List.fromList(utf8.encode(jsonEncode(envelope)));
    final cipher = AesGcm.with256bits();

    // Generate random salt (32 bytes) and nonce (12 bytes)
    final salt = Uint8List.fromList([
      ...cipher.newNonce(),
      ...cipher.newNonce(),
      ...cipher.newNonce().sublist(0, 8),
    ]);
    final nonce = cipher.newNonce();

    final key = await _deriveKey(passphrase, salt);
    final secretBox = await cipher.encrypt(
      plaintext,
      secretKey: key,
      nonce: nonce,
    );

    // Format: salt(32) + nonce(12) + ciphertext + mac(16)
    return [
      ...salt,
      ...nonce,
      ...secretBox.cipherText,
      ...secretBox.mac.bytes,
    ];
  }

  Future<VaultSnapshotDto> decode({
    required List<int> encryptedPayload,
    required String passphrase,
  }) async {
    _validatePassphrase(passphrase);

    if (encryptedPayload.length < 44 + 16) {
      // Check for legacy XOR format (v1) — try to decode
      return _decodeLegacy(encryptedPayload, passphrase);
    }

    try {
      final data = Uint8List.fromList(encryptedPayload);
      final salt = data.sublist(0, 32);
      final nonce = data.sublist(32, 44);
      final ciphertextWithMac = data.sublist(44);

      const macLength = 16;
      if (ciphertextWithMac.length < macLength) {
        return _decodeLegacy(encryptedPayload, passphrase);
      }

      final ciphertext =
          ciphertextWithMac.sublist(0, ciphertextWithMac.length - macLength);
      final mac = ciphertextWithMac.sublist(ciphertextWithMac.length - macLength);

      final key = await _deriveKey(passphrase, salt);
      final cipher = AesGcm.with256bits();

      final secretBox = SecretBox(
        ciphertext,
        nonce: nonce,
        mac: Mac(mac),
      );

      final plaintext = await cipher.decrypt(secretBox, secretKey: key);
      final raw =
          jsonDecode(utf8.decode(plaintext)) as Map<String, dynamic>;

      if (!_isSupportedMagic(raw['magic'])) {
        throw const FormatException('Unsupported backup format.');
      }

      return VaultSnapshotDto.fromMap(
        raw['snapshot'] as Map<String, dynamic>,
      );
    } catch (e) {
      // If AES decryption fails, try legacy XOR as fallback
      if (e is FormatException) rethrow;
      return _decodeLegacy(encryptedPayload, passphrase);
    }
  }

  /// Legacy XOR decode for backwards compatibility with v1 exports.
  VaultSnapshotDto _decodeLegacy(List<int> payload, String passphrase) {
    try {
      final key = utf8.encode(passphrase);
      final decoded = List<int>.generate(
        payload.length,
        (i) => payload[i] ^ key[i % key.length],
        growable: false,
      );
      final raw =
          jsonDecode(utf8.decode(decoded)) as Map<String, dynamic>;
      if (!_isSupportedMagic(raw['magic'])) {
        throw const FormatException('Unsupported backup format.');
      }
      return VaultSnapshotDto.fromMap(
        raw['snapshot'] as Map<String, dynamic>,
      );
    } catch (_) {
      throw const FormatException(
        'Invalid backup payload or incorrect passphrase.',
      );
    }
  }

  Future<SecretKey> _deriveKey(String passphrase, List<int> salt) async {
    final argon2id = Argon2id(
      memory: 19456, // ~19 MB — OWASP recommended minimum
      iterations: 3,
      parallelism: 1,
      hashLength: 32,
    );
    return argon2id.deriveKey(
      secretKey: SecretKey(utf8.encode(passphrase)),
      nonce: salt,
    );
  }

  void _validatePassphrase(String passphrase) {
    if (passphrase.trim().isEmpty) {
      throw const FormatException('Passphrase is required.');
    }
  }
}

/// Magic marker written into new exports.
const String _magic = 'CREDENCE_VAULT_EXPORT';

/// Legacy marker accepted (read-only) so exports made before the rebrand still
/// decode.
const String _legacyMagic = 'PDM_VAULT_EXPORT';

bool _isSupportedMagic(Object? magic) =>
    magic == _magic || magic == _legacyMagic;
