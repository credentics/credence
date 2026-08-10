import 'dart:math';

import 'package:hive/hive.dart';
import 'package:pass_doc_manager/data/password_tools/dtos/generated_password_history_entry_dto.dart';
import 'package:pass_doc_manager/data/shared/storage/encrypted_hive_box_factory.dart';

class PasswordHistoryLocalDataSource {
  PasswordHistoryLocalDataSource._({required Box<dynamic> box}) : _box = box;

  static const _historyBoxName = 'credence_generator_history_v1';
  static const _maxEntries = 120;

  final Box<dynamic> _box;

  static Future<PasswordHistoryLocalDataSource> create() async {
    final box = await EncryptedHiveBoxFactory.openEncryptedBox(_historyBoxName);
    return PasswordHistoryLocalDataSource._(box: box);
  }

  Future<void> saveGeneratedPasswordEntry({
    required String password,
    required int length,
    int? score,
  }) async {
    final now = DateTime.now().toUtc();
    final entry = GeneratedPasswordHistoryEntryDto(
      id: _nextId(now),
      password: password,
      createdAtIso: now.toIso8601String(),
      length: length,
      score: score,
    );

    await _box.put(entry.id, entry.toMap());
    await _trimOldEntries();
  }

  Future<List<GeneratedPasswordHistoryEntryDto>> getGeneratedPasswordHistory({
    int limit = 24,
  }) async {
    final rows =
        _box.values
            .map(_rowFromRaw)
            .map(GeneratedPasswordHistoryEntryDto.fromMap)
            .toList(growable: false)
          ..sort(_sortByCreatedAtDesc);

    final safeLimit = limit.clamp(1, _maxEntries);
    if (rows.length <= safeLimit) {
      return rows;
    }
    return rows.take(safeLimit).toList(growable: false);
  }

  Future<void> clearGeneratedPasswordHistory() async {
    await _box.clear();
  }

  Future<void> _trimOldEntries() async {
    final rows =
        _box.values
            .map(_rowFromRaw)
            .map(GeneratedPasswordHistoryEntryDto.fromMap)
            .toList(growable: false)
          ..sort(_sortByCreatedAtDesc);

    if (rows.length <= _maxEntries) {
      return;
    }

    final staleEntries = rows.skip(_maxEntries);
    for (final entry in staleEntries) {
      await _box.delete(entry.id);
    }
  }

  String _nextId(DateTime now) {
    final random = Random.secure();
    final suffix = random.nextInt(0xFFFFFF).toRadixString(16).padLeft(6, '0');
    return 'gen_${now.microsecondsSinceEpoch}_$suffix';
  }

  int _sortByCreatedAtDesc(
    GeneratedPasswordHistoryEntryDto a,
    GeneratedPasswordHistoryEntryDto b,
  ) {
    final aTime =
        DateTime.tryParse(a.createdAtIso)?.millisecondsSinceEpoch ?? 0;
    final bTime =
        DateTime.tryParse(b.createdAtIso)?.millisecondsSinceEpoch ?? 0;
    return bTime.compareTo(aTime);
  }

  Map<String, dynamic> _rowFromRaw(dynamic raw) {
    if (raw is Map<String, dynamic>) {
      return raw;
    }
    if (raw is Map) {
      return Map<String, dynamic>.from(raw);
    }
    throw StateError(
      'Invalid generator-history row format in encrypted store.',
    );
  }
}
