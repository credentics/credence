import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:pass_doc_manager/data/shared/storage/encrypted_hive_box_factory.dart';

/// Test harness that lets code using [EncryptedHiveBoxFactory] run under
/// `flutter test`: it fakes `path_provider` (temp dir) and
/// `flutter_secure_storage` (in-memory), so real encrypted Hive boxes open on
/// disk in a scratch directory.
///
/// Usage:
/// ```dart
/// late HiveTestHarness harness;
/// setUp(() async => harness = await HiveTestHarness.start());
/// tearDown(() async => harness.stop());
/// ```
class HiveTestHarness {
  HiveTestHarness._(this.directory);

  final Directory directory;

  static Future<HiveTestHarness> start() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final dir = await Directory.systemTemp.createTemp('credence_hive_test');
    PathProviderPlatform.instance = _FakePathProviderPlatform(dir.path);
    FlutterSecureStorage.setMockInitialValues(<String, String>{});
    EncryptedHiveBoxFactory.resetAll();
    return HiveTestHarness._(dir);
  }

  Future<void> stop() async {
    await Hive.close();
    EncryptedHiveBoxFactory.resetAll();
    if (directory.existsSync()) {
      directory.deleteSync(recursive: true);
    }
  }
}

class _FakePathProviderPlatform extends PathProviderPlatform
    with MockPlatformInterfaceMixin {
  _FakePathProviderPlatform(this.root);

  final String root;

  Directory _sub(String name) {
    final dir = Directory('$root/$name');
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }
    return dir;
  }

  @override
  Future<String?> getApplicationDocumentsPath() async => _sub('documents').path;

  @override
  Future<String?> getApplicationSupportPath() async => _sub('support').path;

  @override
  Future<String?> getTemporaryPath() async => _sub('tmp').path;

  @override
  Future<String?> getApplicationCachePath() async => _sub('cache').path;
}
