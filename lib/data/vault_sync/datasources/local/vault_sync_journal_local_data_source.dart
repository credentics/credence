import 'package:hive/hive.dart';
import 'package:pass_doc_manager/data/shared/storage/encrypted_hive_box_factory.dart';
import 'package:pass_doc_manager/domain/vault_sync/entities/vault_sync_operation_entity.dart';

class VaultSyncJournalLocalDataSource {
  VaultSyncJournalLocalDataSource._({required Box<dynamic> box}) : _box = box;

  static const _boxName = 'credence_sync_journal_v1';
  static const _contentIndexKey = 'content_index';
  static const _contentPayloadIndexKey = 'content_payload_index';
  static const _operationLogKey = 'operation_log';
  static const _latestSequenceKey = 'latest_sequence';
  static const _appliedOperationIdsKey = 'applied_operation_ids';

  final Box<dynamic> _box;

  static Future<VaultSyncJournalLocalDataSource> create() async {
    final box = await EncryptedHiveBoxFactory.openEncryptedBox(_boxName);
    return VaultSyncJournalLocalDataSource._(box: box);
  }

  Future<Map<String, String>> readContentIndex() async {
    final raw = _box.get(_contentIndexKey);
    if (raw is! Map) {
      return const <String, String>{};
    }
    return Map<String, String>.fromEntries(
      raw.entries.map((entry) => MapEntry('${entry.key}', '${entry.value}')),
    );
  }

  Future<void> writeContentIndex(Map<String, String> index) async {
    await _box.put(_contentIndexKey, Map<String, String>.from(index));
  }

  Future<Map<String, Map<String, dynamic>>> readContentPayloadIndex() async {
    final raw = _box.get(_contentPayloadIndexKey);
    if (raw is! Map) {
      return const <String, Map<String, dynamic>>{};
    }
    final result = <String, Map<String, dynamic>>{};
    for (final entry in raw.entries) {
      final value = entry.value;
      if (value is Map) {
        result['${entry.key}'] = Map<String, dynamic>.from(value);
      }
    }
    return Map<String, Map<String, dynamic>>.unmodifiable(result);
  }

  Future<void> writeContentPayloadIndex(
    Map<String, Map<String, dynamic>> index,
  ) async {
    await _box.put(
      _contentPayloadIndexKey,
      index.map(
        (key, value) => MapEntry(key, Map<String, dynamic>.from(value)),
      ),
    );
  }

  Future<int> readLatestSequence() async {
    final raw = _box.get(_latestSequenceKey);
    if (raw is int) return raw;
    if (raw is num) return raw.toInt();
    return int.tryParse('$raw') ?? 0;
  }

  Future<void> writeLatestSequence(int sequence) async {
    await _box.put(_latestSequenceKey, sequence);
  }

  Future<void> clearLocalOperations({bool resetSequence = true}) async {
    await _box.put(_operationLogKey, const <Map<String, dynamic>>[]);
    if (resetSequence) {
      await _box.put(_latestSequenceKey, 0);
    }
  }

  Future<List<VaultSyncOperationEntity>> readOperations() async {
    final raw = _box.get(_operationLogKey);
    if (raw is! List) {
      return const <VaultSyncOperationEntity>[];
    }
    return raw
        .whereType<Map>()
        .map(
          (item) =>
              VaultSyncOperationEntity.fromMap(Map<String, dynamic>.from(item)),
        )
        .toList(growable: false)
      ..sort((a, b) => a.sequence.compareTo(b.sequence));
  }

  Future<List<VaultSyncOperationEntity>> readPendingUploadOperations() async {
    return (await readOperations())
        .where((operation) => !operation.uploaded)
        .toList(growable: false);
  }

  Future<Set<String>> readKnownOperationIds() async {
    final operations = await readOperations();
    final appliedRaw = _box.get(_appliedOperationIdsKey);
    return {
      for (final operation in operations) operation.opId,
      if (appliedRaw is List)
        ...appliedRaw
            .map((item) => '$item'.trim())
            .where((id) => id.isNotEmpty),
    };
  }

  Future<void> saveLocalOperations(
    List<VaultSyncOperationEntity> operations,
  ) async {
    if (operations.isEmpty) {
      return;
    }
    final existing = await readOperations();
    final byId = <String, VaultSyncOperationEntity>{
      for (final operation in existing) operation.opId: operation,
    };
    for (final operation in operations) {
      byId[operation.opId] = operation;
    }
    final next = byId.values.toList(growable: false)
      ..sort((a, b) => a.sequence.compareTo(b.sequence));
    await _box.put(
      _operationLogKey,
      next
          .map((operation) => operation.toMap(includeLocalState: true))
          .toList(growable: false),
    );
  }

  Future<void> markUploaded(Set<String> operationIds) async {
    if (operationIds.isEmpty) {
      return;
    }
    final updated = (await readOperations())
        .map(
          (operation) => operationIds.contains(operation.opId)
              ? operation.copyWith(uploaded: true)
              : operation,
        )
        .toList(growable: false);
    await _box.put(
      _operationLogKey,
      updated
          .map((operation) => operation.toMap(includeLocalState: true))
          .toList(growable: false),
    );
  }

  Future<void> markRemoteOperationsApplied(
    Iterable<VaultSyncOperationEntity> operations,
  ) async {
    final existing = await readKnownOperationIds();
    existing.addAll(
      operations
          .map((operation) => operation.opId)
          .where((id) => id.isNotEmpty),
    );
    await _box.put(_appliedOperationIdsKey, existing.toList(growable: false));
  }
}
