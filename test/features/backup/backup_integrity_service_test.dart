import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:pass_doc_manager/features/backup/infrastructure/services/backup_integrity_service.dart';

void main() {
  final service = BackupIntegrityService();
  final bytes = Uint8List.fromList(List<int>.generate(256, (i) => i));

  group('BackupIntegrityService.validateArchiveBytes', () {
    test('accepts a matching byte hash', () async {
      final hash = await service.computeHash(bytes);
      expect(hash, startsWith('sha256:'));
      expect(await service.validateArchiveBytes(bytes, hash), isTrue);
    });

    test('rejects a wrong byte hash', () async {
      expect(
        await service.validateArchiveBytes(bytes, 'sha256:deadbeef'),
        isFalse,
      );
    });

    test('skips validation for a non-byte-hash (mirror manifest checksum)',
        () async {
      // Bare base64url value with no sha256: prefix — cannot be a hash of
      // these bytes, so it is not enforced here (GCM MAC guards integrity).
      expect(
        await service.validateArchiveBytes(bytes, 'abc123_base64url'),
        isTrue,
      );
    });

    test('skips validation for an empty expected hash', () async {
      expect(await service.validateArchiveBytes(bytes, ''), isTrue);
    });
  });
}
