import 'dart:async';
import 'dart:convert';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

class BackupCryptoResult {
  const BackupCryptoResult({
    required this.ciphertext,
    required this.salt,
    required this.nonce,
  });

  /// The encrypted bytes (ciphertext + MAC appended by AES-GCM).
  final Uint8List ciphertext;

  /// 32-byte random salt, base64-encoded.
  final String salt;

  /// 12-byte random nonce, base64-encoded.
  final String nonce;
}

class BackupCryptoService {
  /// Encrypts [plaintext] with AES-256-GCM using a key derived from
  /// [passphrase] via Argon2id. Argon2id (~19 MB, 3 iterations) is a deliberate
  /// CPU+memory burner — running it on the UI isolate freezes animations and
  /// can fire the iOS watchdog. We offload the derivation + encryption to a
  /// worker isolate so the main thread stays responsive during backups.
  Future<BackupCryptoResult> encrypt({
    required Uint8List plaintext,
    required String passphrase,
  }) {
    return Isolate.run(
      () => _encryptInIsolate(plaintext, passphrase),
      debugName: 'backup-crypto-encrypt',
    );
  }

  /// Decrypts [ciphertext] that was produced by [encrypt].
  ///
  /// Requires the same [passphrase] and the base64-encoded [salt] and [nonce]
  /// that were returned alongside the ciphertext.
  Future<Uint8List> decrypt({
    required Uint8List ciphertext,
    required String passphrase,
    required String salt,
    required String nonce,
  }) {
    return Isolate.run(
      () => _decryptInIsolate(ciphertext, passphrase, salt, nonce),
      debugName: 'backup-crypto-decrypt',
    );
  }
}

Future<SecretKey> _deriveKeyInIsolate(
  String passphrase,
  List<int> saltBytes,
) {
  final argon2id = Argon2id(
    memory: 19456, // ~19 MB — OWASP recommended minimum
    iterations: 3,
    parallelism: 1,
    hashLength: 32, // 256 bits for AES-256
  );

  return argon2id.deriveKey(
    secretKey: SecretKey(utf8.encode(passphrase)),
    nonce: saltBytes,
  );
}

Future<BackupCryptoResult> _encryptInIsolate(
  Uint8List plaintext,
  String passphrase,
) async {
  final cipher = AesGcm.with256bits();

  final nonceBytes = cipher.newNonce();
  final salt = Uint8List.fromList([
    ...cipher.newNonce(),
    ...cipher.newNonce(),
    ...cipher.newNonce().sublist(0, 8),
  ]);

  final secretKey = await _deriveKeyInIsolate(passphrase, salt);

  final secretBox = await cipher.encrypt(
    plaintext,
    secretKey: secretKey,
    nonce: nonceBytes,
  );

  final ciphertextWithMac = Uint8List.fromList(
    secretBox.cipherText + secretBox.mac.bytes,
  );

  return BackupCryptoResult(
    ciphertext: ciphertextWithMac,
    salt: base64.encode(salt),
    nonce: base64.encode(nonceBytes),
  );
}

Future<Uint8List> _decryptInIsolate(
  Uint8List ciphertext,
  String passphrase,
  String salt,
  String nonce,
) async {
  final cipher = AesGcm.with256bits();
  const macLength = 16; // AES-GCM MAC is 16 bytes

  final saltBytes = base64.decode(salt);
  final nonceBytes = base64.decode(nonce);

  final secretKey = await _deriveKeyInIsolate(passphrase, saltBytes);

  final encryptedData = ciphertext.sublist(0, ciphertext.length - macLength);
  final macBytes = ciphertext.sublist(ciphertext.length - macLength);

  final secretBox = SecretBox(
    encryptedData,
    nonce: nonceBytes,
    mac: Mac(macBytes),
  );

  final plaintext = await cipher.decrypt(
    secretBox,
    secretKey: secretKey,
  );

  return Uint8List.fromList(plaintext);
}
