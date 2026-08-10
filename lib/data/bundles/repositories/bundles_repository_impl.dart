import 'package:pass_doc_manager/data/bundles/datasources/local/bundles_local_data_source.dart';
import 'package:pass_doc_manager/data/bundles/dtos/bundle_record_dto.dart';
import 'package:pass_doc_manager/domain/bundles/entities/bundle_entity.dart';
import 'package:pass_doc_manager/domain/bundles/entities/bundle_event.dart';
import 'package:pass_doc_manager/domain/bundles/entities/bundle_item_ref.dart';
import 'package:pass_doc_manager/domain/bundles/entities/bundle_item_type.dart';
import 'package:pass_doc_manager/domain/bundles/entities/bundle_status.dart';
import 'package:pass_doc_manager/domain/bundles/repositories/bundle_repository.dart';

class BundlesRepositoryImpl implements BundleRepository {
  const BundlesRepositoryImpl({required this.localDataSource});

  final BundlesLocalDataSource localDataSource;

  @override
  Future<List<BundleEntity>> getBundles() async {
    final records = await localDataSource.getBundles();
    return records.map(_toEntity).toList(growable: false)
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  @override
  Future<BundleEntity> getBundleById({required String bundleId}) async {
    final records = await localDataSource.getBundles();
    final match = _findById(records, bundleId);
    if (match == null) {
      throw StateError('Bundle not found: $bundleId');
    }
    return _toEntity(match);
  }

  @override
  Future<BundleEntity> createBundle({
    required String title,
    String? purpose,
    String? description,
    String? templateKey,
  }) async {
    final now = DateTime.now();
    final records = await localDataSource.getBundles();
    final id = localDataSource.nextBundleId();
    final initialEvent = BundleEventRecordDto(
      id: localDataSource.nextEventId(),
      kindKey: BundleEventKind.created.storageKey,
      atIso: now.toIso8601String(),
      detail: title,
    );
    final record = BundleRecordDto(
      id: id,
      title: title,
      purpose: _nullIfBlank(purpose),
      description: _nullIfBlank(description),
      templateKey: _nullIfBlank(templateKey),
      statusKey: BundleStatus.draft.storageKey,
      items: const [],
      history: [initialEvent],
      createdAtIso: now.toIso8601String(),
      updatedAtIso: now.toIso8601String(),
      lastExportedAtIso: null,
      lastExportPath: null,
    );
    await localDataSource.saveBundles([...records, record]);
    return _toEntity(record);
  }

  @override
  Future<BundleEntity> saveBundle(BundleEntity bundle) async {
    final records = await localDataSource.getBundles();
    final existing = _findById(records, bundle.id);
    if (existing == null) {
      throw StateError('Bundle not found: ${bundle.id}');
    }
    final updated = _fromEntity(bundle.copyWith(updatedAt: DateTime.now()));
    await localDataSource.saveBundles(
      records
          .map((record) => record.id == bundle.id ? updated : record)
          .toList(growable: false),
    );
    return _toEntity(updated);
  }

  @override
  Future<void> deleteBundle({required String bundleId}) async {
    final records = await localDataSource.getBundles();
    final filtered = records
        .where((record) => record.id != bundleId)
        .toList(growable: false);
    if (filtered.length == records.length) {
      return;
    }
    await localDataSource.saveBundles(filtered);
  }

  @override
  Future<BundleEntity> addItem({
    required String bundleId,
    required BundleItemRef item,
  }) async {
    final records = await localDataSource.getBundles();
    final existing = _findById(records, bundleId);
    if (existing == null) {
      throw StateError('Bundle not found: $bundleId');
    }

    // De-dupe: same (type, refId) → no-op.
    final alreadyPresent = existing.items.any(
      (i) => i.typeKey == item.type.storageKey && i.refId == item.refId,
    );
    if (alreadyPresent) {
      return _toEntity(existing);
    }

    final now = DateTime.now();
    final itemId = item.id.trim().isEmpty
        ? localDataSource.nextItemId()
        : item.id;
    final newItem = BundleItemRecordDto(
      id: itemId,
      typeKey: item.type.storageKey,
      refId: item.refId,
      displayName: item.displayName,
      subtitle: _nullIfBlank(item.subtitle),
      addedAtIso: item.addedAt.toIso8601String(),
    );
    final event = BundleEventRecordDto(
      id: localDataSource.nextEventId(),
      kindKey: BundleEventKind.itemAdded.storageKey,
      atIso: now.toIso8601String(),
      detail: item.displayName,
    );
    final updated = BundleRecordDto(
      id: existing.id,
      title: existing.title,
      purpose: existing.purpose,
      description: existing.description,
      templateKey: existing.templateKey,
      statusKey: existing.statusKey,
      items: [...existing.items, newItem],
      history: [...existing.history, event],
      createdAtIso: existing.createdAtIso,
      updatedAtIso: now.toIso8601String(),
      lastExportedAtIso: existing.lastExportedAtIso,
      lastExportPath: existing.lastExportPath,
    );

    await localDataSource.saveBundles(
      records
          .map((record) => record.id == bundleId ? updated : record)
          .toList(growable: false),
    );
    return _toEntity(updated);
  }

  @override
  Future<BundleEntity> removeItem({
    required String bundleId,
    required String itemId,
  }) async {
    final records = await localDataSource.getBundles();
    final existing = _findById(records, bundleId);
    if (existing == null) {
      throw StateError('Bundle not found: $bundleId');
    }
    final removed = existing.items
        .where((item) => item.id == itemId)
        .cast<BundleItemRecordDto?>()
        .firstWhere((_) => true, orElse: () => null);
    if (removed == null) {
      return _toEntity(existing);
    }

    final now = DateTime.now();
    final remainingItems = existing.items
        .where((item) => item.id != itemId)
        .toList(growable: false);
    final event = BundleEventRecordDto(
      id: localDataSource.nextEventId(),
      kindKey: BundleEventKind.itemRemoved.storageKey,
      atIso: now.toIso8601String(),
      detail: removed.displayName,
    );
    final updated = BundleRecordDto(
      id: existing.id,
      title: existing.title,
      purpose: existing.purpose,
      description: existing.description,
      templateKey: existing.templateKey,
      statusKey: existing.statusKey,
      items: remainingItems,
      history: [...existing.history, event],
      createdAtIso: existing.createdAtIso,
      updatedAtIso: now.toIso8601String(),
      lastExportedAtIso: existing.lastExportedAtIso,
      lastExportPath: existing.lastExportPath,
    );

    await localDataSource.saveBundles(
      records
          .map((record) => record.id == bundleId ? updated : record)
          .toList(growable: false),
    );
    return _toEntity(updated);
  }

  @override
  Future<BundleEntity> setStatus({
    required String bundleId,
    required BundleStatus status,
  }) async {
    final records = await localDataSource.getBundles();
    final existing = _findById(records, bundleId);
    if (existing == null) {
      throw StateError('Bundle not found: $bundleId');
    }
    if (existing.statusKey == status.storageKey) {
      return _toEntity(existing);
    }

    final now = DateTime.now();
    final event = BundleEventRecordDto(
      id: localDataSource.nextEventId(),
      kindKey: BundleEventKind.statusChanged.storageKey,
      atIso: now.toIso8601String(),
      detail: status.storageKey,
    );
    final updated = BundleRecordDto(
      id: existing.id,
      title: existing.title,
      purpose: existing.purpose,
      description: existing.description,
      templateKey: existing.templateKey,
      statusKey: status.storageKey,
      items: existing.items,
      history: [...existing.history, event],
      createdAtIso: existing.createdAtIso,
      updatedAtIso: now.toIso8601String(),
      lastExportedAtIso: existing.lastExportedAtIso,
      lastExportPath: existing.lastExportPath,
    );

    await localDataSource.saveBundles(
      records
          .map((record) => record.id == bundleId ? updated : record)
          .toList(growable: false),
    );
    return _toEntity(updated);
  }

  // ---------------------------------------------------------------------------
  // Mapping

  BundleEntity _toEntity(BundleRecordDto dto) {
    return BundleEntity(
      id: dto.id,
      title: dto.title,
      purpose: dto.purpose,
      description: dto.description,
      templateKey: dto.templateKey,
      status: BundleStatus.fromStorageKey(dto.statusKey),
      items: dto.items
          .map(_itemToEntity)
          .whereType<BundleItemRef>()
          .toList(growable: false),
      history:
          dto.history
              .map(_eventToEntity)
              .whereType<BundleEvent>()
              .toList(growable: false)
            ..sort((a, b) => a.at.compareTo(b.at)),
      createdAt: _parseDate(dto.createdAtIso) ?? DateTime.now(),
      updatedAt: _parseDate(dto.updatedAtIso) ?? DateTime.now(),
      lastExportedAt: _parseDate(dto.lastExportedAtIso),
      lastExportPath: dto.lastExportPath,
    );
  }

  BundleItemRef? _itemToEntity(BundleItemRecordDto dto) {
    final type = BundleItemType.fromStorageKey(dto.typeKey);
    if (type == null) return null;
    return BundleItemRef(
      id: dto.id,
      type: type,
      refId: dto.refId,
      displayName: dto.displayName,
      subtitle: dto.subtitle,
      addedAt: _parseDate(dto.addedAtIso) ?? DateTime.now(),
    );
  }

  BundleEvent? _eventToEntity(BundleEventRecordDto dto) {
    final kind = BundleEventKind.fromStorageKey(dto.kindKey);
    if (kind == null) return null;
    return BundleEvent(
      id: dto.id,
      kind: kind,
      at: _parseDate(dto.atIso) ?? DateTime.now(),
      detail: dto.detail,
    );
  }

  BundleRecordDto _fromEntity(BundleEntity entity) {
    return BundleRecordDto(
      id: entity.id,
      title: entity.title,
      purpose: _nullIfBlank(entity.purpose),
      description: _nullIfBlank(entity.description),
      templateKey: _nullIfBlank(entity.templateKey),
      statusKey: entity.status.storageKey,
      items: entity.items
          .map(
            (item) => BundleItemRecordDto(
              id: item.id,
              typeKey: item.type.storageKey,
              refId: item.refId,
              displayName: item.displayName,
              subtitle: _nullIfBlank(item.subtitle),
              addedAtIso: item.addedAt.toIso8601String(),
            ),
          )
          .toList(growable: false),
      history: entity.history
          .map(
            (event) => BundleEventRecordDto(
              id: event.id,
              kindKey: event.kind.storageKey,
              atIso: event.at.toIso8601String(),
              detail: _nullIfBlank(event.detail),
            ),
          )
          .toList(growable: false),
      createdAtIso: entity.createdAt.toIso8601String(),
      updatedAtIso: entity.updatedAt.toIso8601String(),
      lastExportedAtIso: entity.lastExportedAt?.toIso8601String(),
      lastExportPath: _nullIfBlank(entity.lastExportPath),
    );
  }

  // ---------------------------------------------------------------------------
  // Helpers

  BundleRecordDto? _findById(List<BundleRecordDto> records, String id) {
    for (final record in records) {
      if (record.id == id) return record;
    }
    return null;
  }

  DateTime? _parseDate(String? iso) {
    if (iso == null || iso.isEmpty) return null;
    return DateTime.tryParse(iso);
  }

  String? _nullIfBlank(String? value) {
    if (value == null) return null;
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}
