import 'package:flutter_test/flutter_test.dart';
import 'package:pass_doc_manager/data/secure_share/services/secure_share_service.dart';
import 'package:pass_doc_manager/domain/secure_share/entities/share_payload_entity.dart';

String _dataParam(String link) {
  final fragment = Uri.parse(link).fragment; // e.g. data=....
  final match = RegExp(r'data=([^&]+)').firstMatch(fragment);
  return match!.group(1)!;
}

void main() {
  final service = SecureShareService();
  const fields = {'username': 'alice', 'password': 's3cr3t!'};

  group('SecureShareService v2 (Argon2id)', () {
    test('round-trips fields with the correct passphrase', () async {
      final result = await service.generateShareLink(
        fields: fields,
        passphrase: 'correct horse battery staple',
        ttl: ShareTtl.oneHour,
      );
      expect(result.link, startsWith('credence://share#data='));

      final decoded = await service.decryptShareLink(
        encodedData: _dataParam(result.link),
        passphrase: 'correct horse battery staple',
      );
      expect(decoded, fields);
    });

    test('fails with the wrong passphrase', () async {
      final result = await service.generateShareLink(
        fields: fields,
        passphrase: 'right-one',
        ttl: ShareTtl.oneDay,
      );
      expect(
        () => service.decryptShareLink(
          encodedData: _dataParam(result.link),
          passphrase: 'wrong-one',
        ),
        throwsA(isA<Exception>()),
      );
    });

    test('detects tampering with the payload', () async {
      final result = await service.generateShareLink(
        fields: fields,
        passphrase: 'pw',
        ttl: ShareTtl.sevenDays,
      );
      final data = _dataParam(result.link);
      // Flip a character in the middle of the ciphertext region.
      final mid = data.length ~/ 2;
      final flipped = data.replaceRange(
        mid,
        mid + 1,
        data[mid] == 'A' ? 'B' : 'A',
      );
      expect(
        () => service.decryptShareLink(encodedData: flipped, passphrase: 'pw'),
        throwsA(isA<Exception>()),
      );
    });

    test('expiry is in the future for a fresh link', () async {
      final result = await service.generateShareLink(
        fields: fields,
        passphrase: 'pw',
        ttl: ShareTtl.oneHour,
      );
      expect(result.expiresAt.isAfter(DateTime.now()), isTrue);
    });
  });
}
