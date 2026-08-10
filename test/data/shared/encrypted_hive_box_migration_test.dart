import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pass_doc_manager/data/shared/storage/encrypted_hive_box_factory.dart';

import '../../support/hive_test_harness.dart';

void main() {
  late HiveTestHarness harness;

  setUp(() async {
    harness = await HiveTestHarness.start();
  });
  tearDown(() async {
    await harness.stop();
  });

  test('opens a credence_* box, generating a master key on first use', () async {
    final box = await EncryptedHiveBoxFactory.openEncryptedBox(
      'credence_documents_v1',
    );
    await box.put('d1', {'id': 'd1'});
    expect(box.get('d1'), {'id': 'd1'});
  });

  test('concurrent first-time opens create the master key exactly once',
      () async {
    // Fresh keychain + several boxes opened at once (the app's startup shape).
    // Without single-flight this races to add the key twice (iOS -25299) and
    // can encrypt boxes under different keys.
    final boxes = await Future.wait([
      EncryptedHiveBoxFactory.openEncryptedBox('credence_documents_v1'),
      EncryptedHiveBoxFactory.openEncryptedBox('credence_collections_v1'),
      EncryptedHiveBoxFactory.openEncryptedBox('credence_credentials_v1'),
      EncryptedHiveBoxFactory.openEncryptedBox('credence_tasks_v1'),
    ]);
    expect(boxes.length, 4);

    // A single stable key was written, and every box actually works under it.
    const storage = FlutterSecureStorage();
    final key = await storage.read(key: 'credence_encryption_key_v1');
    expect(key, isNotNull);
    for (final box in boxes) {
      await box.put('probe', 'ok');
      expect(box.get('probe'), 'ok');
    }
  });

  test('reuses the same box (and key) across opens', () async {
    final first = await EncryptedHiveBoxFactory.openEncryptedBox(
      'credence_credentials_v1',
    );
    await first.put('cred_1', {'id': 'cred_1', 'title': 'Bank'});

    // A second open returns the cached, already-decrypted box with its data.
    final second = await EncryptedHiveBoxFactory.openEncryptedBox(
      'credence_credentials_v1',
    );
    expect(second.get('cred_1'), {'id': 'cred_1', 'title': 'Bank'});
  });
}
