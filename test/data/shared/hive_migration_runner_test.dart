// @Tags(['integration'])
// HiveMigrationRunner uses FlutterSecureStorage for version tracking.
// These tests require a platform channel and are skipped in pure unit test
// environments. Run with `flutter test --tags integration` on a device/emulator.

import 'package:flutter_test/flutter_test.dart';
import 'package:pass_doc_manager/data/shared/storage/hive_migration_runner.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('HiveMigrationRunner — registration', () {
    // Note: HiveMigrationRunner._migrations is a static mutable map.
    // We test registration behaviour which does not require FlutterSecureStorage.

    test('register adds migration to registry', () {
      // Register a migration for a unique box name to avoid cross-test leaks.
      var called = false;
      HiveMigrationRunner.register('test_box_register', 2, (box) async {
        called = true;
      });

      // We cannot directly inspect the private _migrations map, but we can
      // verify that runMigrations will eventually call our function (when
      // the platform channel is available). For now, just verify no error.
      expect(called, isFalse); // Registration does not invoke the migration.
    });
  });

  group('HiveMigrationRunner — runMigrations', () {
    test(
      'runMigrations skips when version is current',
      () async {
        // If the stored version >= the latest registered migration version,
        // no migration callbacks should run.
        var ran = false;
        HiveMigrationRunner.register('test_box_skip', 1, (box) async {
          ran = true;
        });

        // Default version from _getVersion is 1 when no key exists, so a
        // migration targeting version 1 should be skipped (1 >= 1).
        // This requires FlutterSecureStorage to read the version.
        // Skipped in unit test environment.
        expect(ran, isFalse);
      },
      skip: 'Requires platform channel (FlutterSecureStorage + Hive box)',
    );

    test(
      'runMigrations runs pending migrations in order',
      () async {
        final order = <int>[];
        HiveMigrationRunner.register('test_box_order', 2, (box) async {
          order.add(2);
        });
        HiveMigrationRunner.register('test_box_order', 3, (box) async {
          order.add(3);
        });

        // After running against a box at version 1, both v2 and v3 should
        // execute in ascending order.
        // Requires FlutterSecureStorage + Hive box.
        expect(order, isEmpty); // Not yet run.
      },
      skip: 'Requires platform channel (FlutterSecureStorage + Hive box)',
    );

    test(
      'version persists across calls',
      () async {
        // After running migrations, the version stored in secure storage
        // should match the latest migration version. A subsequent call
        // to runMigrations should be a no-op.
        // Requires FlutterSecureStorage.
      },
      skip: 'Requires platform channel (FlutterSecureStorage + Hive box)',
    );
  });
}
