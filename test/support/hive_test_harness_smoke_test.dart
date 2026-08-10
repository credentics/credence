import 'package:flutter_test/flutter_test.dart';
import 'package:pass_doc_manager/data/shared/storage/encrypted_hive_box_factory.dart';

import 'hive_test_harness.dart';

void main() {
  late HiveTestHarness harness;

  setUp(() async {
    harness = await HiveTestHarness.start();
  });
  tearDown(() async {
    await harness.stop();
  });

  test('opens a real encrypted Hive box and round-trips a value', () async {
    final box = await EncryptedHiveBoxFactory.openEncryptedBox('smoke_box');
    await box.put('k', {'v': 1});
    expect(box.get('k'), {'v': 1});
  });
}
