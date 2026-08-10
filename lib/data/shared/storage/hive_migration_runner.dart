import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive/hive.dart';

typedef BoxMigration = Future<void> Function(Box<dynamic> box);

class HiveMigrationRunner {
  HiveMigrationRunner._();

  static const _versionKeyPrefix = 'hive_schema_version:';

  static const FlutterSecureStorage _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  /// Registry of migrations per box.
  /// Key = box name, Value = list of (targetVersion, migration) pairs,
  /// ordered ascending.
  static final Map<String, List<({int version, BoxMigration migrate})>>
      _migrations = {};

  /// Register a migration for a box.
  static void register(String boxName, int version, BoxMigration migrate) {
    _migrations.putIfAbsent(boxName, () => []);
    _migrations[boxName]!.add((version: version, migrate: migrate));
    _migrations[boxName]!.sort((a, b) => a.version.compareTo(b.version));
  }

  /// Run any pending migrations for the given box.
  /// Call this right after opening the box, before returning it.
  static Future<void> runMigrations(String boxName, Box<dynamic> box) async {
    final migrations = _migrations[boxName];
    if (migrations == null || migrations.isEmpty) return;

    final currentVersion = await _getVersion(boxName);
    final targetVersion = migrations.last.version;

    if (currentVersion >= targetVersion) return;

    for (final entry in migrations) {
      if (entry.version <= currentVersion) continue;
      await entry.migrate(box);
      await _setVersion(boxName, entry.version);
    }
  }

  static Future<int> _getVersion(String boxName) async {
    final raw = await _storage.read(key: '$_versionKeyPrefix$boxName');
    return int.tryParse(raw ?? '') ?? 1; // Default v1 for existing boxes
  }

  static Future<void> _setVersion(String boxName, int version) async {
    await _storage.write(
      key: '$_versionKeyPrefix$boxName',
      value: '$version',
    );
  }
}
