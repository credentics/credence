import 'dart:async';
import 'dart:convert';
import 'dart:isolate';
import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:pass_doc_manager/domain/secure_share/entities/share_payload_entity.dart';
import 'package:pass_doc_manager/domain/secure_share/repositories/secure_share_repository.dart';

class SecureShareService implements SecureShareRepository {
  static const String _shareScheme = 'credence://share';

  /// Marker byte for the v2 payload layout:
  /// `[0x02][salt(16)][nonce(12)][ciphertext+mac]`.
  static const int _formatV2 = 0x02;
  static const int _saltLength = 16;
  static const int _nonceLength = 12;

  @override
  Future<ShareLinkResult> generateShareLink({
    required Map<String, String> fields,
    required String passphrase,
    required ShareTtl ttl,
  }) async {
    try {
      final ttlSeconds = _getTtlSeconds(ttl);
      final expiresAt = DateTime.now().add(Duration(seconds: ttlSeconds));

      // The expiry lives INSIDE the authenticated envelope, so it cannot be
      // edited without breaking the AES-GCM MAC. An unmodified link therefore
      // self-expires and a tampered one fails to decrypt.
      final envelope = <String, dynamic>{
        'v': 2,
        'exp': expiresAt.millisecondsSinceEpoch,
        'fields': fields,
      };
      final plaintext = utf8.encode(jsonEncode(envelope));

      final salt = _randomBytes(_saltLength);
      final nonce = _randomBytes(_nonceLength);

      final cipherText = await _encryptInIsolate(
        plaintext: plaintext,
        passphrase: passphrase,
        salt: salt,
        nonce: nonce,
      );

      final payload = <int>[_formatV2, ...salt, ...nonce, ...cipherText];
      final base64Payload = base64Url.encode(payload).replaceAll('=', '');
      final link = '$_shareScheme#data=$base64Payload';

      return ShareLinkResult(link: link, expiresAt: expiresAt);
    } catch (e) {
      throw Exception('Failed to generate share link: $e');
    }
  }

  @override
  Future<Map<String, String>> decryptShareLink({
    required String encodedData,
    required String passphrase,
  }) async {
    final combined = _decodeBase64Url(encodedData);
    try {
      return await _decryptV2(combined, passphrase);
    } on _ShareExpiredException {
      rethrow;
    } catch (e) {
      throw Exception('Failed to decrypt share link: $e');
    }
  }

  Future<Map<String, String>> _decryptV2(
    List<int> combined,
    String passphrase,
  ) async {
    const headerEnd = 1 + _saltLength + _nonceLength;
    if (combined.length < headerEnd + 16) {
      throw const FormatException('Share payload is too short.');
    }
    final salt = combined.sublist(1, 1 + _saltLength);
    final nonce = combined.sublist(1 + _saltLength, headerEnd);
    final cipherText = combined.sublist(headerEnd);

    final plaintext = await _decryptInIsolate(
      cipherText: cipherText,
      passphrase: passphrase,
      salt: salt,
      nonce: nonce,
    );

    final envelope = jsonDecode(utf8.decode(plaintext)) as Map<String, dynamic>;
    _enforceExpiry(envelope['exp']);
    final rawFields = envelope['fields'] as Map<String, dynamic>? ?? const {};
    return rawFields.map((key, value) => MapEntry(key, value.toString()));
  }

  void _enforceExpiry(dynamic exp) {
    if (exp is! int) return;
    final expiresAt = DateTime.fromMillisecondsSinceEpoch(exp);
    if (DateTime.now().isAfter(expiresAt)) {
      throw const _ShareExpiredException();
    }
  }

  List<int> _decodeBase64Url(String encodedData) {
    var value = encodedData;
    final remainder = value.length % 4;
    if (remainder != 0) {
      value = value + ('=' * (4 - remainder));
    }
    return base64Url.decode(value);
  }

  Uint8List _randomBytes(int length) {
    final random = Random.secure();
    return Uint8List.fromList(
      List<int>.generate(length, (_) => random.nextInt(256)),
    );
  }

  int _getTtlSeconds(ShareTtl ttl) {
    switch (ttl) {
      case ShareTtl.oneHour:
        return 3600;
      case ShareTtl.oneDay:
        return 86400;
      case ShareTtl.sevenDays:
        return 604800;
    }
  }
}

class _ShareExpiredException implements Exception {
  const _ShareExpiredException();

  @override
  String toString() =>
      'This share link has expired. Ask the sender for a new one.';
}

// ── Isolate workers (Argon2id is CPU+memory heavy; keep it off the UI). ──

Future<SecretKey> _deriveShareKey(String passphrase, List<int> salt) {
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

Future<List<int>> _encryptInIsolate({
  required List<int> plaintext,
  required String passphrase,
  required List<int> salt,
  required List<int> nonce,
}) {
  return Isolate.run(() async {
    final key = await _deriveShareKey(passphrase, salt);
    final box = await AesGcm.with256bits().encrypt(
      plaintext,
      secretKey: key,
      nonce: nonce,
    );
    return <int>[...box.cipherText, ...box.mac.bytes];
  });
}

Future<List<int>> _decryptInIsolate({
  required List<int> cipherText,
  required String passphrase,
  required List<int> salt,
  required List<int> nonce,
}) {
  return Isolate.run(() async {
    const macLength = 16;
    final key = await _deriveShareKey(passphrase, salt);
    final data = cipherText.sublist(0, cipherText.length - macLength);
    final mac = cipherText.sublist(cipherText.length - macLength);
    final plaintext = await AesGcm.with256bits().decrypt(
      SecretBox(data, nonce: nonce, mac: Mac(mac)),
      secretKey: key,
    );
    return plaintext;
  });
}
