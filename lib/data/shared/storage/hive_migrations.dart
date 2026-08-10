// ignore: unused_import
import 'package:pass_doc_manager/data/shared/storage/hive_migration_runner.dart';

/// Register all Hive box migrations here.
/// Called once at app startup before any boxes are opened.
///
/// Example of adding a v2 migration:
/// ```dart
/// HiveMigrationRunner.register('credence_credentials_v1', 2, (box) async {
///   // Add 'mfaEnabled' field to all credential records
///   for (final key in box.keys) {
///     final record = box.get(key) as Map?;
///     if (record != null && !record.containsKey('mfa_enabled')) {
///       record['mfa_enabled'] = false;
///       await box.put(key, record);
///     }
///   }
/// });
/// ```
void registerHiveMigrations() {
  // v1 is the initial version — no migrations needed yet.
  // Add future migrations here as the schema evolves.
}
