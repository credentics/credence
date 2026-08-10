import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:pass_doc_manager/data/shared/storage/encrypted_hive_box_factory.dart';
import 'package:pass_doc_manager/features/backup/infrastructure/services/backup_replay_engine.dart';

import '../../support/hive_test_harness.dart';

Uint8List _json(Object value) => Uint8List.fromList(utf8.encode(jsonEncode(value)));

void main() {
  late HiveTestHarness harness;
  final engine = BackupReplayEngine();

  setUp(() async {
    harness = await HiveTestHarness.start();
  });
  tearDown(() async {
    await harness.stop();
  });

  test('restores box data from a valid archive', () async {
    await engine.restoreFromArchive({
      'data/credentials.json': _json({
        'cred_1': {'id': 'cred_1', 'title': 'Email'},
      }),
    });

    final box = await EncryptedHiveBoxFactory.openEncryptedBox(
      'credence_credentials_v1',
    );
    expect(box.get('cred_1'), {'id': 'cred_1', 'title': 'Email'});
  });

  test('a corrupt archive aborts BEFORE any box is wiped', () async {
    // Seed a live credentials box with data that must survive a failed restore.
    final creds = await EncryptedHiveBoxFactory.openEncryptedBox(
      'credence_credentials_v1',
    );
    await creds.put('keep_me', {'id': 'keep_me'});

    // documents.json is not valid JSON → validation must throw in phase 1,
    // before phase 2 clears/writes anything.
    await expectLater(
      engine.restoreFromArchive({
        'data/documents.json': Uint8List.fromList(utf8.encode('{ not json')),
      }),
      throwsA(isA<FormatException>()),
    );

    // The pre-existing credential is untouched — no partial wipe.
    final after = await EncryptedHiveBoxFactory.openEncryptedBox(
      'credence_credentials_v1',
    );
    expect(after.get('keep_me'), {'id': 'keep_me'});
  });

  test('restore replaces existing box contents on success', () async {
    final box = await EncryptedHiveBoxFactory.openEncryptedBox(
      'credence_credentials_v1',
    );
    await box.put('old', {'id': 'old'});

    await engine.restoreFromArchive({
      'data/credentials.json': _json({
        'new': {'id': 'new'},
      }),
    });

    final after = await EncryptedHiveBoxFactory.openEncryptedBox(
      'credence_credentials_v1',
    );
    expect(after.get('old'), isNull);
    expect(after.get('new'), {'id': 'new'});
  });

  test('restores multiple boxes atomically', () async {
    await engine.restoreFromArchive({
      'data/credentials.json': _json({
        'c1': {'id': 'c1'},
      }),
      'data/documents.json': _json({
        'd1': {'id': 'd1'},
      }),
    });

    final creds = await EncryptedHiveBoxFactory.openEncryptedBox(
      'credence_credentials_v1',
    );
    final docs = await EncryptedHiveBoxFactory.openEncryptedBox(
      'credence_documents_v1',
    );
    expect(creds.get('c1'), {'id': 'c1'});
    expect(docs.get('d1'), {'id': 'd1'});
  });
}
