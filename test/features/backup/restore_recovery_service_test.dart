import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pass_doc_manager/features/backup/presentation/cubit/restore_recovery_service.dart';

import '../../support/hive_test_harness.dart';

void main() {
  late HiveTestHarness harness;
  final service = RestoreRecoveryService();

  setUp(() async {
    harness = await HiveTestHarness.start();
  });
  tearDown(() async {
    await harness.stop();
  });

  Future<Directory> rollbackDir() async {
    final support = await getApplicationSupportDirectory();
    return Directory('${support.path}${Platform.pathSeparator}restore_rollback');
  }

  test('reports no interrupted restore when the rollback dir is absent', () async {
    expect(await service.hasInterruptedRestore(), isFalse);
  });

  test('detects an interrupted restore when the rollback dir exists', () async {
    await (await rollbackDir()).create(recursive: true);
    expect(await service.hasInterruptedRestore(), isTrue);
  });

  test('discardRollback removes the directory', () async {
    final dir = await rollbackDir();
    await dir.create(recursive: true);
    expect(dir.existsSync(), isTrue);

    await service.discardRollback();

    expect(dir.existsSync(), isFalse);
    expect(await service.hasInterruptedRestore(), isFalse);
  });

  test('discardRollback is a no-op when nothing to roll back', () async {
    await service.discardRollback(); // must not throw
    expect(await service.hasInterruptedRestore(), isFalse);
  });
}
