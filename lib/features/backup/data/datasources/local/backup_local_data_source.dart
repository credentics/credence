import 'package:pass_doc_manager/data/shared/storage/encrypted_hive_box_factory.dart';
import 'package:pass_doc_manager/features/backup/data/dtos/journal_entry_dto.dart';

/// Local data source for the backup journal, chain state, and device identity.
/// Uses a dedicated Hive box: credence_backup_journal_v1
class BackupLocalDataSource {
  static const String _boxName = 'credence_backup_journal_v1';
  static const String _journalKey = 'journal_entries';
  static const String _chainStateKey = 'chain_state';
  static const String _deviceKey = 'device_identity';
  static const String _sequenceKey = 'sequence_counter';
  static const String _manifestsKey = 'local_manifests';

  late final dynamic _box;

  static Future<BackupLocalDataSource> create() async {
    final ds = BackupLocalDataSource();
    ds._box = await EncryptedHiveBoxFactory.openEncryptedBox(_boxName);
    return ds;
  }

  // ── Journal ──

  Future<void> recordJournalEntry(BackupJournalEntryDto entry) async {
    final raw = _box.get(_journalKey);
    final entries = <dynamic>[
      if (raw is List) ...raw,
      entry.toMap(),
    ];
    await _box.put(_journalKey, entries);
  }

  Future<List<BackupJournalEntryDto>> getEntriesSince(int sequenceNumber) async {
    final raw = _box.get(_journalKey);
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((m) => BackupJournalEntryDto.fromMap(Map<String, dynamic>.from(m)))
        .where((e) => e.sequenceNumber > sequenceNumber)
        .toList(growable: false)
      ..sort((a, b) => a.sequenceNumber.compareTo(b.sequenceNumber));
  }

  Future<List<BackupJournalEntryDto>> getAllEntries() async {
    final raw = _box.get(_journalKey);
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((m) => BackupJournalEntryDto.fromMap(Map<String, dynamic>.from(m)))
        .toList(growable: false)
      ..sort((a, b) => a.sequenceNumber.compareTo(b.sequenceNumber));
  }

  Future<int> nextSequenceNumber() async {
    final current = _box.get(_sequenceKey) as int? ?? 0;
    final next = current + 1;
    await _box.put(_sequenceKey, next);
    return next;
  }

  Future<int> getLatestSequence() async {
    return _box.get(_sequenceKey) as int? ?? 0;
  }

  Future<void> pruneEntriesBefore(int sequenceNumber) async {
    final raw = _box.get(_journalKey);
    if (raw is! List) return;
    final kept = raw
        .whereType<Map>()
        .where((m) => (m['sequence_number'] as int? ?? 0) >= sequenceNumber)
        .toList(growable: false);
    await _box.put(_journalKey, kept);
  }

  // ── Chain State ──

  Future<Map<String, dynamic>?> getChainState() async {
    final raw = _box.get(_chainStateKey);
    if (raw is Map) return Map<String, dynamic>.from(raw);
    return null;
  }

  Future<void> updateChainState(Map<String, dynamic> state) async {
    await _box.put(_chainStateKey, state);
  }

  // ── Device Identity ──

  Future<Map<String, dynamic>?> getDeviceIdentity() async {
    final raw = _box.get(_deviceKey);
    if (raw is Map) return Map<String, dynamic>.from(raw);
    return null;
  }

  Future<void> saveDeviceIdentity(Map<String, dynamic> identity) async {
    await _box.put(_deviceKey, identity);
  }

  // ── Local Manifests ──

  Future<List<Map<String, dynamic>>> getLocalManifests() async {
    final raw = _box.get(_manifestsKey);
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((m) => Map<String, dynamic>.from(m))
        .toList(growable: false);
  }

  Future<void> saveLocalManifest(Map<String, dynamic> manifest) async {
    final raw = _box.get(_manifestsKey);
    final manifests = <dynamic>[
      if (raw is List) ...raw,
      manifest,
    ];
    await _box.put(_manifestsKey, manifests);
  }

  Future<void> removeLocalManifest(String backupId) async {
    final raw = _box.get(_manifestsKey);
    if (raw is! List) return;
    final kept = raw
        .whereType<Map>()
        .where((m) => m['backup_id'] != backupId)
        .toList(growable: false);
    await _box.put(_manifestsKey, kept);
  }
}
