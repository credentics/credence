import 'package:pass_doc_manager/data/collections/datasources/local/collections_local_data_source.dart';
import 'package:pass_doc_manager/data/collections/dtos/collection_record_dto.dart';
import 'package:pass_doc_manager/core/constants/internal_collection_ids.dart';
import 'package:pass_doc_manager/domain/collections/entities/collection_block_entity.dart';
import 'package:pass_doc_manager/domain/collections/entities/collection_block_type.dart';
import 'package:pass_doc_manager/domain/collections/entities/collection_checklist_item_entity.dart';
import 'package:pass_doc_manager/domain/collections/entities/collection_entity.dart';
import 'package:pass_doc_manager/domain/collections/entities/collection_template_type.dart';
import 'package:flutter/foundation.dart';
import 'package:pass_doc_manager/domain/collections/repositories/collections_repository.dart';
import 'package:pass_doc_manager/features/backup/data/datasources/local/backup_local_data_source.dart';
import 'package:pass_doc_manager/features/backup/data/dtos/journal_entry_dto.dart';
import 'package:pass_doc_manager/features/collections/presentation/services/reminder_notification_service.dart';

class CollectionsRepositoryImpl implements CollectionsRepository {
  const CollectionsRepositoryImpl({
    required this.localDataSource,
    this.backupDataSource,
  });

  final CollectionsLocalDataSource localDataSource;
  final BackupLocalDataSource? backupDataSource;

  @override
  Future<List<CollectionEntity>> getCollections() async {
    final records = await localDataSource.getCollections();
    return records
        .where((record) => record.id != internalSecureNotesCollectionId)
        .map(_toEntity)
        .toList(growable: false)
      ..sort(_compareCollections);
  }

  @override
  Future<CollectionEntity> getCollectionById({
    required String collectionId,
  }) async {
    if (collectionId == internalSecureNotesCollectionId) {
      throw StateError('Collection not found: $collectionId');
    }

    final records = await localDataSource.getCollections();
    CollectionRecordDto? match;
    for (final item in records) {
      if (item.id == collectionId) {
        match = item;
        break;
      }
    }
    if (match == null) {
      throw StateError('Collection not found: $collectionId');
    }
    return _toEntity(match);
  }

  @override
  Future<CollectionEntity> createCollection({
    required String name,
    required String iconKey,
    String? iconEmoji,
    String? iconImagePath,
    required String accentColorHex,
    required CollectionTemplateType template,
  }) async {
    final now = DateTime.now();
    final records = await localDataSource.getCollections();
    final nextPosition = records.isEmpty
        ? 0
        : records
                  .map((item) => item.position)
                  .reduce((current, next) => current > next ? current : next) +
              1;
    final collectionId = localDataSource.nextCollectionId();
    final blocks = _templateBlocks(
      collectionId: collectionId,
      template: template,
      now: now,
    );
    final record = CollectionRecordDto(
      id: collectionId,
      name: name,
      subtitle: _templateSubtitle(template),
      iconKey: iconKey,
      iconEmoji: iconEmoji,
      iconImagePath: iconImagePath,
      accentColorHex: accentColorHex,
      startDateIso: template == CollectionTemplateType.travelPlanner
          ? now.add(const Duration(days: 7)).toIso8601String()
          : null,
      endDateIso: template == CollectionTemplateType.travelPlanner
          ? now.add(const Duration(days: 14)).toIso8601String()
          : null,
      coverImageUrl: _templateCover(template),
      updatedAtIso: now.toIso8601String(),
      blocks: blocks,
      position: nextPosition,
    );
    _logCollectionRecord('Collections/createCollection', record);

    final updated = [...records, record];
    await localDataSource.saveCollections(updated);
    await _recordJournal('create', collectionId, 'collection');
    return _toEntity(record);
  }

  @override
  Future<void> saveCollection(CollectionEntity collection) async {
    final records = await localDataSource.getCollections();
    final updatedRecord = _toRecord(collection);
    _logCollectionRecord('Collections/saveCollection', updatedRecord);
    final next = records
        .map((item) => item.id == collection.id ? updatedRecord : item)
        .toList(growable: false);
    await localDataSource.saveCollections(next);
    await _recordJournal('update', collection.id, 'collection');
  }

  @override
  Future<void> reorderCollections({
    required List<String> orderedCollectionIds,
  }) async {
    if (orderedCollectionIds.isEmpty) {
      return;
    }

    final records = await localDataSource.getCollections();
    final orderedCurrent = records.toList(growable: false)
      ..sort(_compareRecords);
    final recordById = {for (final record in orderedCurrent) record.id: record};
    final visibleRecords = orderedCollectionIds
        .map(recordById.remove)
        .whereType<CollectionRecordDto>()
        .toList(growable: false);

    if (visibleRecords.length != orderedCollectionIds.length) {
      throw StateError(
        'Failed to reorder collections: some IDs were not found',
      );
    }

    final visibleIds = orderedCollectionIds.toSet();
    var visibleIndex = 0;
    final reordered = <CollectionRecordDto>[];
    for (final record in orderedCurrent) {
      if (visibleIds.contains(record.id)) {
        reordered.add(visibleRecords[visibleIndex++]);
      } else {
        reordered.add(record);
      }
    }

    final normalized = [
      for (var i = 0; i < reordered.length; i++)
        reordered[i].copyWith(position: i),
    ];
    await localDataSource.saveCollections(normalized);
    for (final id in orderedCollectionIds) {
      await _recordJournal(
        'update',
        id,
        'collection',
        metadata: const {'change': 'reorder'},
      );
    }
  }

  @override
  Future<void> saveBlock({
    required String collectionId,
    required CollectionBlockEntity block,
  }) async {
    final records = await localDataSource.getCollections();
    final now = DateTime.now();
    final next = <CollectionRecordDto>[];

    for (final collection in records) {
      if (collection.id != collectionId) {
        next.add(collection);
        continue;
      }

      final blockRecord = _toBlockRecord(
        block.copyWith(updatedAt: now, createdAt: block.createdAt),
      );
      _logCollectionRecord(
        'Collections/saveBlock.before',
        collection,
        block: blockRecord,
      );
      debugPrint(
        '[saveBlock] Saving block id="${blockRecord.id}" to collection="$collectionId"',
      );
      debugPrint(
        '[saveBlock] Collection has ${collection.blocks.length} blocks',
      );
      debugPrint(
        '[saveBlock] Existing block IDs: ${collection.blocks.map((b) => b.id).toList()}',
      );
      final updatedBlocks = <CollectionBlockRecordDto>[];
      var wasUpdated = false;
      for (final existing in collection.blocks) {
        if (existing.id == blockRecord.id) {
          updatedBlocks.add(blockRecord);
          wasUpdated = true;
        } else {
          updatedBlocks.add(existing);
        }
      }
      debugPrint('[saveBlock] wasUpdated=$wasUpdated');
      if (!wasUpdated) {
        final siblingCount = updatedBlocks
            .where((b) => b.parentBlockId == blockRecord.parentBlockId)
            .length;
        updatedBlocks.add(
          CollectionBlockRecordDto(
            id: blockRecord.id,
            collectionId: blockRecord.collectionId,
            parentBlockId: blockRecord.parentBlockId,
            typeKey: blockRecord.typeKey,
            title: blockRecord.title,
            subtitle: blockRecord.subtitle,
            description: blockRecord.description,
            createdAtIso: blockRecord.createdAtIso,
            updatedAtIso: blockRecord.updatedAtIso,
            imageUrl: blockRecord.imageUrl,
            fileType: blockRecord.fileType,
            fileSizeLabel: blockRecord.fileSizeLabel,
            url: blockRecord.url,
            domainLabel: blockRecord.domainLabel,
            currencyCode: blockRecord.currencyCode,
            amount: blockRecord.amount,
            eventAtIso: blockRecord.eventAtIso,
            expiryDateIso: blockRecord.expiryDateIso,
            latitude: blockRecord.latitude,
            longitude: blockRecord.longitude,
            locationLabel: blockRecord.locationLabel,
            isCompleted: blockRecord.isCompleted,
            statusLabel: blockRecord.statusLabel,
            tags: blockRecord.tags,
            metadata: blockRecord.metadata,
            checklistItems: blockRecord.checklistItems,
            position: siblingCount,
            filePath: blockRecord.filePath,
            repeatInterval: blockRecord.repeatInterval,
          ),
        );
      }

      final updatedCollection = collection.copyWith(
        updatedAtIso: now.toIso8601String(),
        blocks: updatedBlocks,
      );
      if (_collectionIconSummary(updatedCollection) !=
          _collectionIconSummary(collection)) {
        debugPrint(
          '[Collections/saveBlock.warn] collection=$collectionId icon state changed unexpectedly before=${_collectionIconSummary(collection)} after=${_collectionIconSummary(updatedCollection)}',
        );
      }
      _logCollectionRecord(
        'Collections/saveBlock.after',
        updatedCollection,
        block: blockRecord,
      );
      next.add(updatedCollection);
    }

    await localDataSource.saveCollections(next);
    await _recordJournal('update', block.id, 'collection_block');
  }

  @override
  Future<void> deleteBlock({
    required String collectionId,
    required String blockId,
  }) async {
    final records = await localDataSource.getCollections();
    final now = DateTime.now();
    final next = <CollectionRecordDto>[];

    for (final collection in records) {
      if (collection.id != collectionId) {
        next.add(collection);
        continue;
      }

      final removeIds = <String>{blockId};
      bool changed = true;
      while (changed) {
        changed = false;
        for (final block in collection.blocks) {
          if (block.parentBlockId != null &&
              removeIds.contains(block.parentBlockId)) {
            if (removeIds.add(block.id)) {
              changed = true;
            }
          }
        }
      }

      final remaining = collection.blocks
          .where((block) => !removeIds.contains(block.id))
          .toList(growable: false);

      next.add(
        collection.copyWith(
          blocks: remaining,
          updatedAtIso: now.toIso8601String(),
        ),
      );
    }

    await localDataSource.saveCollections(next);
    await _recordJournal(
      'delete',
      blockId,
      'collection_block',
      metadata: const {'deleted_entity_type': 'collection_block'},
    );
  }

  CollectionEntity _toEntity(CollectionRecordDto record) {
    return CollectionEntity(
      id: record.id,
      name: record.name,
      subtitle: record.subtitle,
      iconKey: record.iconKey,
      iconEmoji: record.iconEmoji,
      iconImagePath: record.iconImagePath,
      accentColorHex: record.accentColorHex,
      startDate: _parseIso(record.startDateIso),
      endDate: _parseIso(record.endDateIso),
      coverImageUrl: record.coverImageUrl,
      updatedAt: _parseIso(record.updatedAtIso) ?? DateTime.now(),
      blocks: record.blocks.map(_toBlockEntity).toList(growable: false)
        ..sort((a, b) => a.position.compareTo(b.position)),
      position: record.position,
      isPinLocked: record.isPinLocked,
      pinHash: record.pinHash,
    );
  }

  CollectionRecordDto _toRecord(CollectionEntity entity) {
    return CollectionRecordDto(
      id: entity.id,
      name: entity.name,
      subtitle: entity.subtitle,
      iconKey: entity.iconKey,
      iconEmoji: entity.iconEmoji,
      iconImagePath: entity.iconImagePath,
      accentColorHex: entity.accentColorHex,
      startDateIso: entity.startDate?.toIso8601String(),
      endDateIso: entity.endDate?.toIso8601String(),
      coverImageUrl: entity.coverImageUrl,
      updatedAtIso: entity.updatedAt.toIso8601String(),
      blocks: entity.blocks.map(_toBlockRecord).toList(growable: false),
      position: entity.position,
      isPinLocked: entity.isPinLocked,
      pinHash: entity.pinHash,
    );
  }

  CollectionBlockEntity _toBlockEntity(CollectionBlockRecordDto record) {
    return CollectionBlockEntity(
      id: record.id,
      collectionId: record.collectionId,
      parentBlockId: record.parentBlockId,
      type: CollectionBlockTypeX.fromKey(record.typeKey),
      title: record.title,
      subtitle: record.subtitle,
      description: record.description,
      createdAt: _parseIso(record.createdAtIso) ?? DateTime.now(),
      updatedAt: _parseIso(record.updatedAtIso) ?? DateTime.now(),
      imageUrl: record.imageUrl,
      fileType: record.fileType,
      fileSizeLabel: record.fileSizeLabel,
      url: record.url,
      domainLabel: record.domainLabel,
      currencyCode: record.currencyCode,
      amount: record.amount,
      eventAt: _parseIso(record.eventAtIso),
      expiryDate: _parseIso(record.expiryDateIso),
      latitude: record.latitude,
      longitude: record.longitude,
      locationLabel: record.locationLabel,
      isCompleted: record.isCompleted,
      statusLabel: record.statusLabel,
      tags: record.tags,
      metadata: record.metadata,
      checklistItems: record.checklistItems
          .map(
            (item) => CollectionChecklistItemEntity(
              id: item.id,
              title: item.title,
              isDone: item.isDone,
            ),
          )
          .toList(growable: false),
      position: record.position,
      filePath: record.filePath,
      repeatInterval: record.repeatInterval,
    );
  }

  CollectionBlockRecordDto _toBlockRecord(CollectionBlockEntity entity) {
    return CollectionBlockRecordDto(
      id: entity.id,
      collectionId: entity.collectionId,
      parentBlockId: entity.parentBlockId,
      typeKey: entity.type.key,
      title: entity.title,
      subtitle: entity.subtitle,
      description: entity.description,
      createdAtIso: entity.createdAt.toIso8601String(),
      updatedAtIso: entity.updatedAt.toIso8601String(),
      imageUrl: entity.imageUrl,
      fileType: entity.fileType,
      fileSizeLabel: entity.fileSizeLabel,
      url: entity.url,
      domainLabel: entity.domainLabel,
      currencyCode: entity.currencyCode,
      amount: entity.amount,
      eventAtIso: entity.eventAt?.toIso8601String(),
      expiryDateIso: entity.expiryDate?.toIso8601String(),
      latitude: entity.latitude,
      longitude: entity.longitude,
      locationLabel: entity.locationLabel,
      isCompleted: entity.isCompleted,
      statusLabel: entity.statusLabel,
      tags: entity.tags,
      metadata: entity.metadata,
      checklistItems: entity.checklistItems
          .map(
            (item) => CollectionChecklistItemRecordDto(
              id: item.id,
              title: item.title,
              isDone: item.isDone,
            ),
          )
          .toList(growable: false),
      position: entity.position,
      filePath: entity.filePath,
      repeatInterval: entity.repeatInterval,
    );
  }

  @override
  Future<void> deleteCollection({required String collectionId}) async {
    final records = await localDataSource.getCollections();
    final next = records
        .where((item) => item.id != collectionId)
        .toList(growable: false);
    final normalized = [
      for (var i = 0; i < next.length; i++) next[i].copyWith(position: i),
    ];
    await localDataSource.saveCollections(normalized);
    await _recordJournal(
      'delete',
      collectionId,
      'collection',
      metadata: const {'deleted_entity_type': 'collection'},
    );
  }

  @override
  Future<void> scheduleBlockReminder({
    required String blockId,
    required String title,
    String? body,
    required DateTime scheduledAt,
    String? repeatInterval,
  }) {
    return ReminderNotificationService.instance.scheduleReminder(
      id: blockId,
      title: title,
      body: body,
      scheduledAt: scheduledAt,
      repeatInterval: repeatInterval,
    );
  }

  @override
  Future<void> cancelBlockReminder({required String blockId}) {
    return ReminderNotificationService.instance.cancelReminder(blockId);
  }

  Future<void> _recordJournal(
    String operation,
    String entityId,
    String entityType, {
    Map<String, String> metadata = const {},
  }) async {
    if (backupDataSource == null) return;
    try {
      final seq = await backupDataSource!.nextSequenceNumber();
      await backupDataSource!.recordJournalEntry(
        BackupJournalEntryDto(
          journalId: 'j_${DateTime.now().microsecondsSinceEpoch}',
          sequenceNumber: seq,
          deviceId: '',
          timestampIso: DateTime.now().toUtc().toIso8601String(),
          operationKey: operation,
          entityId: entityId,
          entityType: entityType,
          previousRevision: null,
          newRevision: null,
          previousContentHash: null,
          newContentHash: null,
          affectedFileIds: const [],
          metadata: metadata,
        ),
      );
    } catch (_) {
      // Best-effort — don't fail the mutation if journal fails
    }
  }

  void _logCollectionRecord(
    String scope,
    CollectionRecordDto record, {
    CollectionBlockRecordDto? block,
  }) {
    debugPrint(
      '[$scope] collection=${record.id} icon=${_collectionIconSummary(record)}'
      '${block == null ? '' : ' block=${block.id} type=${block.typeKey} parent=${block.parentBlockId ?? 'root'}'}',
    );
  }

  String _collectionIconSummary(CollectionRecordDto record) {
    return 'key=${record.iconKey}'
        ' emoji=${(record.iconEmoji ?? '').trim().isNotEmpty}'
        ' image=${(record.iconImagePath ?? '').trim().isNotEmpty}';
  }

  static int _compareCollections(CollectionEntity a, CollectionEntity b) {
    final positionCompare = a.position.compareTo(b.position);
    if (positionCompare != 0) {
      return positionCompare;
    }
    return b.updatedAt.compareTo(a.updatedAt);
  }

  static int _compareRecords(CollectionRecordDto a, CollectionRecordDto b) {
    final positionCompare = a.position.compareTo(b.position);
    if (positionCompare != 0) {
      return positionCompare;
    }
    return b.updatedAtIso.compareTo(a.updatedAtIso);
  }

  DateTime? _parseIso(String? raw) {
    if (raw == null || raw.trim().isEmpty) {
      return null;
    }
    return DateTime.tryParse(raw);
  }

  // ---------------------------------------------------------------------------
  // Template helpers
  // ---------------------------------------------------------------------------

  CollectionBlockRecordDto _block({
    required String id,
    required String collectionId,
    String? parentBlockId,
    required String typeKey,
    required String title,
    String subtitle = '',
    String description = '',
    required String nowIso,
    int position = 0,
    String? url,
    String? domainLabel,
    String? currencyCode,
    double? amount,
    String? eventAtIso,
    String? locationLabel,
    double? latitude,
    double? longitude,
    String? repeatInterval,
    List<CollectionChecklistItemRecordDto> checklistItems = const [],
    Map<String, String> metadata = const {},
  }) {
    return CollectionBlockRecordDto(
      id: id,
      collectionId: collectionId,
      parentBlockId: parentBlockId,
      typeKey: typeKey,
      title: title,
      subtitle: subtitle,
      description: description,
      createdAtIso: nowIso,
      updatedAtIso: nowIso,
      imageUrl: null,
      fileType: null,
      fileSizeLabel: null,
      url: url,
      domainLabel: domainLabel,
      currencyCode: currencyCode,
      amount: amount,
      eventAtIso: eventAtIso,
      expiryDateIso: null,
      latitude: latitude,
      longitude: longitude,
      locationLabel: locationLabel,
      isCompleted: false,
      statusLabel: null,
      tags: const [],
      metadata: metadata,
      checklistItems: checklistItems,
      position: position,
      repeatInterval: repeatInterval,
    );
  }

  String? _templateCover(CollectionTemplateType template) {
    return switch (template) {
      CollectionTemplateType.blank => null,
      CollectionTemplateType.travelPlanner =>
        'https://images.unsplash.com/photo-1536098561742-ca998e48cbcc?auto=format&fit=crop&w=1600&q=80',
      CollectionTemplateType.propertyManagement =>
        'https://images.unsplash.com/photo-1600607687939-ce8a6c25118c?auto=format&fit=crop&w=1600&q=80',
      CollectionTemplateType.projectPlanning =>
        'https://images.unsplash.com/photo-1497215728101-856f4ea42174?auto=format&fit=crop&w=1600&q=80',
      CollectionTemplateType.eventPlanning =>
        'https://images.unsplash.com/photo-1519671482749-fd09be7ccebf?auto=format&fit=crop&w=1600&q=80',
      CollectionTemplateType.fitnessTracker =>
        'https://images.unsplash.com/photo-1534438327276-14e5300c3a48?auto=format&fit=crop&w=1600&q=80',
      CollectionTemplateType.recipeBook =>
        'https://images.unsplash.com/photo-1466637574441-749b8f19452f?auto=format&fit=crop&w=1600&q=80',
      CollectionTemplateType.jobSearch =>
        'https://images.unsplash.com/photo-1486312338219-ce68d2c6f44d?auto=format&fit=crop&w=1600&q=80',
      CollectionTemplateType.movingChecklist =>
        'https://images.unsplash.com/photo-1600585152220-90363fe7e115?auto=format&fit=crop&w=1600&q=80',
      CollectionTemplateType.petCare =>
        'https://images.unsplash.com/photo-1587300003388-59208cc962cb?auto=format&fit=crop&w=1600&q=80',
      CollectionTemplateType.vehicleMaintenance =>
        'https://images.unsplash.com/photo-1492144534655-ae79c964c9d7?auto=format&fit=crop&w=1600&q=80',
      CollectionTemplateType.budgetPlanner =>
        'https://images.unsplash.com/photo-1554224155-6726b3ff858f?auto=format&fit=crop&w=1400&q=80',
      CollectionTemplateType.studyPlanner =>
        'https://images.unsplash.com/photo-1456513080510-7bf3a84b82f8?auto=format&fit=crop&w=1400&q=80',
      CollectionTemplateType.homeRenovation =>
        'https://images.unsplash.com/photo-1581858726788-75bc0f6a952d?auto=format&fit=crop&w=1400&q=80',
      CollectionTemplateType.weddingPlanner =>
        'https://images.unsplash.com/photo-1519741497674-611481863552?auto=format&fit=crop&w=1400&q=80',
      CollectionTemplateType.freelanceTracker =>
        'https://images.unsplash.com/photo-1522202176988-66273c2fd55f?auto=format&fit=crop&w=1400&q=80',
      CollectionTemplateType.diplomasCertificates =>
        'https://images.unsplash.com/photo-1523050854058-8df90110c476?auto=format&fit=crop&w=1400&q=80',
      CollectionTemplateType.bankDocuments =>
        'https://images.unsplash.com/photo-1554224155-6726b3ff858f?auto=format&fit=crop&w=1400&q=80',
      CollectionTemplateType.healthRecords =>
        'https://images.unsplash.com/photo-1576091160399-112ba8d25d1d?auto=format&fit=crop&w=1400&q=80',
      CollectionTemplateType.taxDocuments =>
        'https://images.unsplash.com/photo-1554224154-26032ffc0d07?auto=format&fit=crop&w=1400&q=80',
      CollectionTemplateType.warrantyTracker =>
        'https://images.unsplash.com/photo-1556742049-0cfed4f6a45d?auto=format&fit=crop&w=1400&q=80',
      CollectionTemplateType.subscriptionManager =>
        'https://images.unsplash.com/photo-1563986768609-322da13575f2?auto=format&fit=crop&w=1400&q=80',
      CollectionTemplateType.homeMaintenance =>
        'https://images.unsplash.com/photo-1581578731548-c64695cc6952?auto=format&fit=crop&w=1400&q=80',
      CollectionTemplateType.movieLibrary =>
        'https://images.unsplash.com/photo-1489599849927-2ee91cede3ba?auto=format&fit=crop&w=1400&q=80',
      CollectionTemplateType.readingList =>
        'https://images.unsplash.com/photo-1512820790803-83ca734da794?auto=format&fit=crop&w=1400&q=80',
      CollectionTemplateType.wineCellar =>
        'https://images.unsplash.com/photo-1506377247377-2a5b3b417ebb?auto=format&fit=crop&w=1400&q=80',
      CollectionTemplateType.medicalTracker =>
        'https://images.unsplash.com/photo-1631549916768-4119b2e5f926?auto=format&fit=crop&w=1400&q=80',
      CollectionTemplateType.emergencyContacts =>
        'https://images.unsplash.com/photo-1529156069898-49953e39b3ac?auto=format&fit=crop&w=1400&q=80',
      CollectionTemplateType.digitalAccounts =>
        'https://images.unsplash.com/photo-1563013544-824ae1b704d3?auto=format&fit=crop&w=1400&q=80',
      CollectionTemplateType.insurancePolicies =>
        'https://images.unsplash.com/photo-1450101499163-c8848c66ca85?auto=format&fit=crop&w=1400&q=80',
    };
  }

  String _templateSubtitle(CollectionTemplateType template) {
    return switch (template) {
      CollectionTemplateType.blank => '0 items \u2022 Just created',
      CollectionTemplateType.travelPlanner => 'Travel workspace ready',
      CollectionTemplateType.propertyManagement => 'Property collection ready',
      CollectionTemplateType.projectPlanning => 'Project workspace ready',
      CollectionTemplateType.eventPlanning => 'Event workspace ready',
      CollectionTemplateType.fitnessTracker => 'Fitness workspace ready',
      CollectionTemplateType.recipeBook => 'Recipe workspace ready',
      CollectionTemplateType.jobSearch => 'Job search workspace ready',
      CollectionTemplateType.movingChecklist => 'Moving workspace ready',
      CollectionTemplateType.petCare => 'Pet care workspace ready',
      CollectionTemplateType.vehicleMaintenance => 'Vehicle workspace ready',
      CollectionTemplateType.budgetPlanner =>
        '5 blocks \u2022 Budget workspace ready',
      CollectionTemplateType.studyPlanner =>
        '6 blocks \u2022 Study workspace ready',
      CollectionTemplateType.homeRenovation =>
        '7 blocks \u2022 Renovation workspace ready',
      CollectionTemplateType.weddingPlanner =>
        '8 blocks \u2022 Wedding workspace ready',
      CollectionTemplateType.freelanceTracker =>
        '30 blocks \u2022 Freelance command center',
      CollectionTemplateType.diplomasCertificates =>
        '6 blocks \u2022 Diploma workspace ready',
      CollectionTemplateType.bankDocuments =>
        '20 blocks \u2022 Banking workspace ready',
      CollectionTemplateType.healthRecords =>
        '7 blocks \u2022 Health workspace ready',
      CollectionTemplateType.taxDocuments =>
        '7 blocks \u2022 Tax workspace ready',
      CollectionTemplateType.warrantyTracker =>
        '16 blocks \u2022 Product warranty workspace',
      CollectionTemplateType.subscriptionManager =>
        '18 blocks \u2022 Subscription tracker ready',
      CollectionTemplateType.homeMaintenance =>
        '30 blocks \u2022 Home maintenance hub',
      CollectionTemplateType.movieLibrary =>
        '18 blocks \u2022 Movie collection ready',
      CollectionTemplateType.readingList =>
        '15 blocks \u2022 Book collection ready',
      CollectionTemplateType.wineCellar =>
        '14 blocks \u2022 Wine collection ready',
      CollectionTemplateType.medicalTracker =>
        '20 blocks \u2022 Health tracker ready',
      CollectionTemplateType.emergencyContacts =>
        '12 blocks \u2022 Emergency contacts ready',
      CollectionTemplateType.digitalAccounts =>
        '16 blocks \u2022 Digital accounts ready',
      CollectionTemplateType.insurancePolicies =>
        '18 blocks \u2022 Insurance tracker ready',
    };
  }

  List<CollectionBlockRecordDto> _templateBlocks({
    required String collectionId,
    required CollectionTemplateType template,
    required DateTime now,
  }) {
    String nextId() => localDataSource.nextBlockId();
    var checkItemCounter = 0;
    String nextCheckItemId() =>
        'chk_${now.microsecondsSinceEpoch}_${checkItemCounter++}';
    final nowIso = now.toIso8601String();

    switch (template) {
      case CollectionTemplateType.blank:
        return const <CollectionBlockRecordDto>[];

      case CollectionTemplateType.travelPlanner:
        return [
          _block(
            id: nextId(),
            collectionId: collectionId,
            typeKey: CollectionBlockType.folder.key,
            title: 'Itinerary',
            subtitle: '0 items',
            description: 'Trip timeline and routing',
            nowIso: nowIso,
            position: 0,
          ),
          _block(
            id: nextId(),
            collectionId: collectionId,
            typeKey: CollectionBlockType.folder.key,
            title: 'Bookings & Tickets',
            subtitle: '0 items',
            description: 'Flights, hotels, tickets',
            nowIso: nowIso,
            position: 1,
          ),
          _block(
            id: nextId(),
            collectionId: collectionId,
            typeKey: CollectionBlockType.folder.key,
            title: 'Budget & Expenses',
            subtitle: '0 items',
            description: 'Budget planning and expenses',
            nowIso: nowIso,
            position: 2,
          ),
        ];

      case CollectionTemplateType.eventPlanning:
        return [
          _block(
            id: nextId(),
            collectionId: collectionId,
            typeKey: CollectionBlockType.section.key,
            title: 'Vendors',
            nowIso: nowIso,
            position: 0,
          ),
          _block(
            id: nextId(),
            collectionId: collectionId,
            typeKey: CollectionBlockType.checklist.key,
            title: 'Venue Setup',
            nowIso: nowIso,
            position: 1,
            checklistItems: [
              CollectionChecklistItemRecordDto(
                id: nextCheckItemId(),
                title: 'Book venue',
                isDone: false,
              ),
              CollectionChecklistItemRecordDto(
                id: nextCheckItemId(),
                title: 'Confirm catering',
                isDone: false,
              ),
              CollectionChecklistItemRecordDto(
                id: nextCheckItemId(),
                title: 'Arrange decorations',
                isDone: false,
              ),
              CollectionChecklistItemRecordDto(
                id: nextCheckItemId(),
                title: 'Sound system check',
                isDone: false,
              ),
            ],
          ),
          _block(
            id: nextId(),
            collectionId: collectionId,
            typeKey: CollectionBlockType.expense.key,
            title: 'Venue Deposit',
            nowIso: nowIso,
            position: 2,
            currencyCode: 'USD',
            amount: 2500,
          ),
          _block(
            id: nextId(),
            collectionId: collectionId,
            typeKey: CollectionBlockType.timeline.key,
            title: 'Ceremony',
            nowIso: nowIso,
            position: 3,
            eventAtIso: DateTime(
              now.year,
              now.month,
              now.day,
              14,
            ).add(const Duration(days: 30)).toIso8601String(),
            locationLabel: 'Grand Ballroom',
          ),
          _block(
            id: nextId(),
            collectionId: collectionId,
            typeKey: CollectionBlockType.note.key,
            title: 'Guest Dietary Notes',
            description:
                'Track dietary restrictions and allergies for all guests.',
            nowIso: nowIso,
            position: 4,
          ),
          _block(
            id: nextId(),
            collectionId: collectionId,
            typeKey: CollectionBlockType.reminder.key,
            title: 'Send invitations',
            nowIso: nowIso,
            position: 5,
            eventAtIso: now.add(const Duration(days: 14)).toIso8601String(),
          ),
        ];

      case CollectionTemplateType.fitnessTracker:
        return [
          _block(
            id: nextId(),
            collectionId: collectionId,
            typeKey: CollectionBlockType.checklist.key,
            title: 'Weekly Workout Plan',
            nowIso: nowIso,
            position: 0,
            checklistItems: [
              CollectionChecklistItemRecordDto(
                id: nextCheckItemId(),
                title: 'Monday - Chest',
                isDone: false,
              ),
              CollectionChecklistItemRecordDto(
                id: nextCheckItemId(),
                title: 'Wednesday - Back',
                isDone: false,
              ),
              CollectionChecklistItemRecordDto(
                id: nextCheckItemId(),
                title: 'Friday - Legs',
                isDone: false,
              ),
              CollectionChecklistItemRecordDto(
                id: nextCheckItemId(),
                title: 'Saturday - Cardio',
                isDone: false,
              ),
            ],
          ),
          _block(
            id: nextId(),
            collectionId: collectionId,
            typeKey: CollectionBlockType.note.key,
            title: 'Personal Records',
            description:
                'Track your personal records here: bench press, squat, deadlift, and more.',
            nowIso: nowIso,
            position: 1,
          ),
          _block(
            id: nextId(),
            collectionId: collectionId,
            typeKey: CollectionBlockType.expense.key,
            title: 'Gym Membership',
            nowIso: nowIso,
            position: 2,
            currencyCode: 'USD',
            amount: 49.99,
          ),
          _block(
            id: nextId(),
            collectionId: collectionId,
            typeKey: CollectionBlockType.link.key,
            title: 'Workout Routines',
            nowIso: nowIso,
            position: 3,
            url: 'https://muscleandstrength.com',
            domainLabel: 'muscleandstrength.com',
          ),
          _block(
            id: nextId(),
            collectionId: collectionId,
            typeKey: CollectionBlockType.reminder.key,
            title: 'Weigh-in',
            nowIso: nowIso,
            position: 4,
            eventAtIso: DateTime(
              now.year,
              now.month,
              now.day,
              7,
            ).add(const Duration(days: 1)).toIso8601String(),
            repeatInterval: 'weekly',
          ),
        ];

      case CollectionTemplateType.recipeBook:
        return [
          _block(
            id: nextId(),
            collectionId: collectionId,
            typeKey: CollectionBlockType.folder.key,
            title: 'Breakfast',
            subtitle: '0 items',
            nowIso: nowIso,
            position: 0,
          ),
          _block(
            id: nextId(),
            collectionId: collectionId,
            typeKey: CollectionBlockType.folder.key,
            title: 'Dinner',
            subtitle: '0 items',
            nowIso: nowIso,
            position: 1,
          ),
          _block(
            id: nextId(),
            collectionId: collectionId,
            typeKey: CollectionBlockType.note.key,
            title: "Grandma's Pasta Sauce",
            description:
                'Ingredients: 2 cans San Marzano tomatoes, 4 cloves garlic, fresh basil, olive oil, salt, pepper, pinch of sugar. Simmer low and slow for 3 hours.',
            nowIso: nowIso,
            position: 2,
          ),
          _block(
            id: nextId(),
            collectionId: collectionId,
            typeKey: CollectionBlockType.checklist.key,
            title: 'Grocery List',
            nowIso: nowIso,
            position: 3,
            checklistItems: [
              CollectionChecklistItemRecordDto(
                id: nextCheckItemId(),
                title: 'Olive oil',
                isDone: false,
              ),
              CollectionChecklistItemRecordDto(
                id: nextCheckItemId(),
                title: 'Fresh basil',
                isDone: false,
              ),
              CollectionChecklistItemRecordDto(
                id: nextCheckItemId(),
                title: 'San Marzano tomatoes',
                isDone: false,
              ),
              CollectionChecklistItemRecordDto(
                id: nextCheckItemId(),
                title: 'Parmesan',
                isDone: false,
              ),
            ],
          ),
          _block(
            id: nextId(),
            collectionId: collectionId,
            typeKey: CollectionBlockType.link.key,
            title: 'Cooking Techniques',
            nowIso: nowIso,
            position: 4,
            url: 'https://seriouseats.com',
            domainLabel: 'seriouseats.com',
          ),
        ];

      case CollectionTemplateType.jobSearch:
        return [
          _block(
            id: nextId(),
            collectionId: collectionId,
            typeKey: CollectionBlockType.section.key,
            title: 'Applications',
            nowIso: nowIso,
            position: 0,
          ),
          _block(
            id: nextId(),
            collectionId: collectionId,
            typeKey: CollectionBlockType.note.key,
            title: 'Resume Notes',
            description:
                'Key skills to highlight: project management, cross-functional collaboration, data-driven decision making.',
            nowIso: nowIso,
            position: 1,
          ),
          _block(
            id: nextId(),
            collectionId: collectionId,
            typeKey: CollectionBlockType.checklist.key,
            title: 'Interview Prep',
            nowIso: nowIso,
            position: 2,
            checklistItems: [
              CollectionChecklistItemRecordDto(
                id: nextCheckItemId(),
                title: 'Research company',
                isDone: false,
              ),
              CollectionChecklistItemRecordDto(
                id: nextCheckItemId(),
                title: 'Practice STAR method',
                isDone: false,
              ),
              CollectionChecklistItemRecordDto(
                id: nextCheckItemId(),
                title: 'Prepare questions',
                isDone: false,
              ),
              CollectionChecklistItemRecordDto(
                id: nextCheckItemId(),
                title: 'Update portfolio',
                isDone: false,
              ),
            ],
          ),
          _block(
            id: nextId(),
            collectionId: collectionId,
            typeKey: CollectionBlockType.timeline.key,
            title: 'Phone Screen - Acme Corp',
            nowIso: nowIso,
            position: 3,
            eventAtIso: DateTime(
              now.year,
              now.month,
              now.day,
              10,
            ).add(const Duration(days: 7)).toIso8601String(),
          ),
          _block(
            id: nextId(),
            collectionId: collectionId,
            typeKey: CollectionBlockType.link.key,
            title: 'LinkedIn Profile',
            nowIso: nowIso,
            position: 4,
            url: 'https://linkedin.com',
            domainLabel: 'linkedin.com',
          ),
          _block(
            id: nextId(),
            collectionId: collectionId,
            typeKey: CollectionBlockType.input.key,
            title: 'Desired Salary',
            subtitle: r'$120,000',
            nowIso: nowIso,
            position: 5,
          ),
          _block(
            id: nextId(),
            collectionId: collectionId,
            typeKey: CollectionBlockType.reminder.key,
            title: 'Follow up on applications',
            nowIso: nowIso,
            position: 6,
            eventAtIso: now.add(const Duration(days: 3)).toIso8601String(),
            repeatInterval: 'weekly',
          ),
        ];

      case CollectionTemplateType.movingChecklist:
        return [
          _block(
            id: nextId(),
            collectionId: collectionId,
            typeKey: CollectionBlockType.section.key,
            title: 'Before Moving Day',
            nowIso: nowIso,
            position: 0,
          ),
          _block(
            id: nextId(),
            collectionId: collectionId,
            typeKey: CollectionBlockType.checklist.key,
            title: 'Packing',
            nowIso: nowIso,
            position: 1,
            checklistItems: [
              CollectionChecklistItemRecordDto(
                id: nextCheckItemId(),
                title: 'Kitchen',
                isDone: false,
              ),
              CollectionChecklistItemRecordDto(
                id: nextCheckItemId(),
                title: 'Bedroom',
                isDone: false,
              ),
              CollectionChecklistItemRecordDto(
                id: nextCheckItemId(),
                title: 'Living room',
                isDone: false,
              ),
              CollectionChecklistItemRecordDto(
                id: nextCheckItemId(),
                title: 'Bathroom',
                isDone: false,
              ),
              CollectionChecklistItemRecordDto(
                id: nextCheckItemId(),
                title: 'Garage',
                isDone: false,
              ),
            ],
          ),
          _block(
            id: nextId(),
            collectionId: collectionId,
            typeKey: CollectionBlockType.checklist.key,
            title: 'Utilities',
            nowIso: nowIso,
            position: 2,
            checklistItems: [
              CollectionChecklistItemRecordDto(
                id: nextCheckItemId(),
                title: 'Cancel old electricity',
                isDone: false,
              ),
              CollectionChecklistItemRecordDto(
                id: nextCheckItemId(),
                title: 'Set up new internet',
                isDone: false,
              ),
              CollectionChecklistItemRecordDto(
                id: nextCheckItemId(),
                title: 'Forward mail',
                isDone: false,
              ),
              CollectionChecklistItemRecordDto(
                id: nextCheckItemId(),
                title: 'Update address',
                isDone: false,
              ),
            ],
          ),
          _block(
            id: nextId(),
            collectionId: collectionId,
            typeKey: CollectionBlockType.expense.key,
            title: 'Moving Company',
            nowIso: nowIso,
            position: 3,
            currencyCode: 'USD',
            amount: 1800,
          ),
          _block(
            id: nextId(),
            collectionId: collectionId,
            typeKey: CollectionBlockType.timeline.key,
            title: 'Moving Day',
            nowIso: nowIso,
            position: 4,
            eventAtIso: DateTime(
              now.year,
              now.month,
              now.day,
              8,
            ).add(const Duration(days: 21)).toIso8601String(),
            locationLabel: 'New Apartment',
          ),
          _block(
            id: nextId(),
            collectionId: collectionId,
            typeKey: CollectionBlockType.reminder.key,
            title: 'Cancel old lease',
            nowIso: nowIso,
            position: 5,
            eventAtIso: now.add(const Duration(days: 7)).toIso8601String(),
          ),
        ];

      case CollectionTemplateType.petCare:
        return [
          _block(
            id: nextId(),
            collectionId: collectionId,
            typeKey: CollectionBlockType.input.key,
            title: 'Microchip ID',
            subtitle: '985141000123456',
            nowIso: nowIso,
            position: 0,
          ),
          _block(
            id: nextId(),
            collectionId: collectionId,
            typeKey: CollectionBlockType.input.key,
            title: 'Breed',
            subtitle: 'Golden Retriever',
            nowIso: nowIso,
            position: 1,
          ),
          _block(
            id: nextId(),
            collectionId: collectionId,
            typeKey: CollectionBlockType.checklist.key,
            title: 'Vaccination Schedule',
            nowIso: nowIso,
            position: 2,
            checklistItems: [
              CollectionChecklistItemRecordDto(
                id: nextCheckItemId(),
                title: 'Rabies',
                isDone: false,
              ),
              CollectionChecklistItemRecordDto(
                id: nextCheckItemId(),
                title: 'DHPP',
                isDone: false,
              ),
              CollectionChecklistItemRecordDto(
                id: nextCheckItemId(),
                title: 'Bordetella',
                isDone: false,
              ),
              CollectionChecklistItemRecordDto(
                id: nextCheckItemId(),
                title: 'Lyme',
                isDone: false,
              ),
            ],
          ),
          _block(
            id: nextId(),
            collectionId: collectionId,
            typeKey: CollectionBlockType.expense.key,
            title: 'Vet Visit',
            nowIso: nowIso,
            position: 3,
            currencyCode: 'USD',
            amount: 250,
          ),
          _block(
            id: nextId(),
            collectionId: collectionId,
            typeKey: CollectionBlockType.note.key,
            title: 'Feeding Schedule',
            description:
                'Morning: 1 cup kibble + joint supplement. Evening: 1 cup kibble + fish oil. Fresh water always available.',
            nowIso: nowIso,
            position: 4,
          ),
          _block(
            id: nextId(),
            collectionId: collectionId,
            typeKey: CollectionBlockType.reminder.key,
            title: 'Flea & tick treatment',
            nowIso: nowIso,
            position: 5,
            eventAtIso: now.add(const Duration(days: 30)).toIso8601String(),
            repeatInterval: 'monthly',
          ),
          _block(
            id: nextId(),
            collectionId: collectionId,
            typeKey: CollectionBlockType.link.key,
            title: 'Pet Insurance',
            nowIso: nowIso,
            position: 6,
            url: 'https://petinsurance.com',
            domainLabel: 'petinsurance.com',
          ),
        ];

      case CollectionTemplateType.vehicleMaintenance:
        return [
          _block(
            id: nextId(),
            collectionId: collectionId,
            typeKey: CollectionBlockType.input.key,
            title: 'VIN',
            subtitle: '1HGBH41JXMN109186',
            nowIso: nowIso,
            position: 0,
          ),
          _block(
            id: nextId(),
            collectionId: collectionId,
            typeKey: CollectionBlockType.input.key,
            title: 'License Plate',
            subtitle: 'ABC-1234',
            nowIso: nowIso,
            position: 1,
          ),
          _block(
            id: nextId(),
            collectionId: collectionId,
            typeKey: CollectionBlockType.expense.key,
            title: 'Oil Change',
            nowIso: nowIso,
            position: 2,
            currencyCode: 'USD',
            amount: 75,
          ),
          _block(
            id: nextId(),
            collectionId: collectionId,
            typeKey: CollectionBlockType.expense.key,
            title: 'New Tires',
            nowIso: nowIso,
            position: 3,
            currencyCode: 'USD',
            amount: 680,
          ),
          _block(
            id: nextId(),
            collectionId: collectionId,
            typeKey: CollectionBlockType.checklist.key,
            title: 'Maintenance Schedule',
            nowIso: nowIso,
            position: 4,
            checklistItems: [
              CollectionChecklistItemRecordDto(
                id: nextCheckItemId(),
                title: 'Oil change 5000mi',
                isDone: false,
              ),
              CollectionChecklistItemRecordDto(
                id: nextCheckItemId(),
                title: 'Tire rotation 7500mi',
                isDone: false,
              ),
              CollectionChecklistItemRecordDto(
                id: nextCheckItemId(),
                title: 'Brake inspection 15000mi',
                isDone: false,
              ),
              CollectionChecklistItemRecordDto(
                id: nextCheckItemId(),
                title: 'Transmission fluid 30000mi',
                isDone: false,
              ),
            ],
          ),
          _block(
            id: nextId(),
            collectionId: collectionId,
            typeKey: CollectionBlockType.timeline.key,
            title: 'Next Service',
            nowIso: nowIso,
            position: 5,
            eventAtIso: DateTime(
              now.year,
              now.month,
              now.day,
              9,
            ).add(const Duration(days: 60)).toIso8601String(),
            locationLabel: 'AutoCare Center',
          ),
          _block(
            id: nextId(),
            collectionId: collectionId,
            typeKey: CollectionBlockType.reminder.key,
            title: 'Insurance renewal',
            nowIso: nowIso,
            position: 6,
            eventAtIso: now.add(const Duration(days: 90)).toIso8601String(),
          ),
        ];

      case CollectionTemplateType.propertyManagement:
        return [
          _block(
            id: nextId(),
            collectionId: collectionId,
            typeKey: CollectionBlockType.folder.key,
            title: 'Documents',
            subtitle: '0 items',
            description: 'General property files and supporting documents',
            nowIso: nowIso,
            position: 0,
          ),
          _block(
            id: nextId(),
            collectionId: collectionId,
            typeKey: CollectionBlockType.folder.key,
            title: 'Contracts & Lease',
            subtitle: '0 items',
            description: 'Lease agreements, amendments, and signed contracts',
            nowIso: nowIso,
            position: 1,
          ),
          _block(
            id: nextId(),
            collectionId: collectionId,
            typeKey: CollectionBlockType.folder.key,
            title: 'Insurance',
            subtitle: '0 items',
            description: 'Insurance policies, certificates, and renewals',
            nowIso: nowIso,
            position: 2,
          ),
          _block(
            id: nextId(),
            collectionId: collectionId,
            typeKey: CollectionBlockType.folder.key,
            title: 'Rent / Quittance',
            subtitle: '0 items',
            description: 'Rent receipts, quittances, and tenant records',
            nowIso: nowIso,
            position: 3,
          ),
          _block(
            id: nextId(),
            collectionId: collectionId,
            typeKey: CollectionBlockType.folder.key,
            title: 'Maintenance',
            subtitle: '0 items',
            description: 'Repairs, inspections, and contractor records',
            nowIso: nowIso,
            position: 4,
          ),
          _block(
            id: nextId(),
            collectionId: collectionId,
            typeKey: CollectionBlockType.folder.key,
            title: 'Utilities',
            subtitle: '0 items',
            description: 'Electricity, water, internet, and service documents',
            nowIso: nowIso,
            position: 5,
          ),
          _block(
            id: nextId(),
            collectionId: collectionId,
            typeKey: CollectionBlockType.input.key,
            title: 'Property Address',
            subtitle: 'Add full address',
            nowIso: nowIso,
            position: 6,
          ),
          _block(
            id: nextId(),
            collectionId: collectionId,
            typeKey: CollectionBlockType.checklist.key,
            title: 'Move-in Inspection',
            nowIso: nowIso,
            position: 7,
            checklistItems: [
              CollectionChecklistItemRecordDto(
                id: nextCheckItemId(),
                title: 'Test all outlets',
                isDone: false,
              ),
              CollectionChecklistItemRecordDto(
                id: nextCheckItemId(),
                title: 'Check water pressure',
                isDone: false,
              ),
              CollectionChecklistItemRecordDto(
                id: nextCheckItemId(),
                title: 'Inspect HVAC',
                isDone: false,
              ),
              CollectionChecklistItemRecordDto(
                id: nextCheckItemId(),
                title: 'Document existing damage',
                isDone: false,
              ),
            ],
          ),
          _block(
            id: nextId(),
            collectionId: collectionId,
            typeKey: CollectionBlockType.reminder.key,
            title: 'Lease renewal check',
            nowIso: nowIso,
            position: 8,
            eventAtIso: DateTime(
              now.year,
              now.month + 11,
              1,
              9,
            ).toIso8601String(),
          ),
        ];

      case CollectionTemplateType.projectPlanning:
        return [
          _block(
            id: nextId(),
            collectionId: collectionId,
            typeKey: CollectionBlockType.section.key,
            title: 'Planning',
            nowIso: nowIso,
            position: 0,
          ),
          _block(
            id: nextId(),
            collectionId: collectionId,
            typeKey: CollectionBlockType.section.key,
            title: 'Resources',
            nowIso: nowIso,
            position: 1,
          ),
          _block(
            id: nextId(),
            collectionId: collectionId,
            typeKey: CollectionBlockType.checklist.key,
            title: 'Sprint Goals',
            nowIso: nowIso,
            position: 2,
            checklistItems: [
              CollectionChecklistItemRecordDto(
                id: nextCheckItemId(),
                title: 'Design mockups',
                isDone: false,
              ),
              CollectionChecklistItemRecordDto(
                id: nextCheckItemId(),
                title: 'API integration',
                isDone: false,
              ),
              CollectionChecklistItemRecordDto(
                id: nextCheckItemId(),
                title: 'Testing',
                isDone: false,
              ),
              CollectionChecklistItemRecordDto(
                id: nextCheckItemId(),
                title: 'Deployment',
                isDone: false,
              ),
            ],
          ),
          _block(
            id: nextId(),
            collectionId: collectionId,
            typeKey: CollectionBlockType.timeline.key,
            title: 'Project Kickoff',
            nowIso: nowIso,
            position: 3,
            eventAtIso: DateTime(
              now.year,
              now.month,
              now.day,
              10,
            ).add(const Duration(days: 3)).toIso8601String(),
          ),
          _block(
            id: nextId(),
            collectionId: collectionId,
            typeKey: CollectionBlockType.note.key,
            title: 'Architecture Decisions',
            description:
                'Document key architecture decisions, trade-offs, and rationale for the tech stack.',
            nowIso: nowIso,
            position: 4,
          ),
          _block(
            id: nextId(),
            collectionId: collectionId,
            typeKey: CollectionBlockType.link.key,
            title: 'Project Board',
            nowIso: nowIso,
            position: 5,
            url: 'https://github.com/orgs/project/projects',
            domainLabel: 'github.com',
          ),
          _block(
            id: nextId(),
            collectionId: collectionId,
            typeKey: CollectionBlockType.reminder.key,
            title: 'Weekly standup',
            nowIso: nowIso,
            position: 6,
            eventAtIso: DateTime(
              now.year,
              now.month,
              now.day,
              9,
              30,
            ).add(const Duration(days: 1)).toIso8601String(),
            repeatInterval: 'weekly',
          ),
        ];

      case CollectionTemplateType.budgetPlanner:
        return [
          _block(
            id: nextId(),
            collectionId: collectionId,
            typeKey: CollectionBlockType.input.key,
            title: 'Monthly Income',
            subtitle: r'$5,000',
            nowIso: nowIso,
            position: 0,
          ),
          _block(
            id: nextId(),
            collectionId: collectionId,
            typeKey: CollectionBlockType.checklist.key,
            title: 'Monthly Bills',
            nowIso: nowIso,
            position: 1,
            checklistItems: [
              CollectionChecklistItemRecordDto(
                id: nextCheckItemId(),
                title: 'Rent',
                isDone: false,
              ),
              CollectionChecklistItemRecordDto(
                id: nextCheckItemId(),
                title: 'Utilities',
                isDone: false,
              ),
              CollectionChecklistItemRecordDto(
                id: nextCheckItemId(),
                title: 'Internet',
                isDone: false,
              ),
              CollectionChecklistItemRecordDto(
                id: nextCheckItemId(),
                title: 'Insurance',
                isDone: false,
              ),
              CollectionChecklistItemRecordDto(
                id: nextCheckItemId(),
                title: 'Subscriptions',
                isDone: false,
              ),
            ],
          ),
          _block(
            id: nextId(),
            collectionId: collectionId,
            typeKey: CollectionBlockType.expense.key,
            title: 'Savings Goal',
            nowIso: nowIso,
            position: 2,
            currencyCode: 'USD',
            amount: 500,
          ),
          _block(
            id: nextId(),
            collectionId: collectionId,
            typeKey: CollectionBlockType.link.key,
            title: 'Budget Spreadsheet',
            nowIso: nowIso,
            position: 3,
            url: 'https://docs.google.com',
            domainLabel: 'docs.google.com',
          ),
          _block(
            id: nextId(),
            collectionId: collectionId,
            typeKey: CollectionBlockType.reminder.key,
            title: 'Review budget',
            nowIso: nowIso,
            position: 4,
            eventAtIso: DateTime(now.year, now.month + 1, 1).toIso8601String(),
            repeatInterval: 'monthly',
          ),
        ];

      case CollectionTemplateType.studyPlanner:
        return [
          _block(
            id: nextId(),
            collectionId: collectionId,
            typeKey: CollectionBlockType.section.key,
            title: 'Courses',
            nowIso: nowIso,
            position: 0,
          ),
          _block(
            id: nextId(),
            collectionId: collectionId,
            typeKey: CollectionBlockType.checklist.key,
            title: 'Study Schedule',
            nowIso: nowIso,
            position: 1,
            checklistItems: [
              CollectionChecklistItemRecordDto(
                id: nextCheckItemId(),
                title: 'Monday - Math',
                isDone: false,
              ),
              CollectionChecklistItemRecordDto(
                id: nextCheckItemId(),
                title: 'Tuesday - Science',
                isDone: false,
              ),
              CollectionChecklistItemRecordDto(
                id: nextCheckItemId(),
                title: 'Wednesday - English',
                isDone: false,
              ),
              CollectionChecklistItemRecordDto(
                id: nextCheckItemId(),
                title: 'Thursday - History',
                isDone: false,
              ),
              CollectionChecklistItemRecordDto(
                id: nextCheckItemId(),
                title: 'Friday - Review',
                isDone: false,
              ),
            ],
          ),
          _block(
            id: nextId(),
            collectionId: collectionId,
            typeKey: CollectionBlockType.timeline.key,
            title: 'Exam Dates',
            nowIso: nowIso,
            position: 2,
            eventAtIso: DateTime(
              now.year,
              now.month,
              now.day,
              9,
            ).add(const Duration(days: 14)).toIso8601String(),
            locationLabel: 'University Hall',
          ),
          _block(
            id: nextId(),
            collectionId: collectionId,
            typeKey: CollectionBlockType.link.key,
            title: 'Study Resources',
            nowIso: nowIso,
            position: 3,
            url: 'https://www.khanacademy.org',
            domainLabel: 'khanacademy.org',
          ),
          _block(
            id: nextId(),
            collectionId: collectionId,
            typeKey: CollectionBlockType.note.key,
            title: 'Assignment Notes',
            description:
                'Keep track of assignments, deadlines, and study notes for each course',
            nowIso: nowIso,
            position: 4,
          ),
          _block(
            id: nextId(),
            collectionId: collectionId,
            typeKey: CollectionBlockType.reminder.key,
            title: 'Study session',
            nowIso: nowIso,
            position: 5,
            eventAtIso: DateTime(
              now.year,
              now.month,
              now.day,
              18,
            ).add(const Duration(days: 1)).toIso8601String(),
            repeatInterval: 'daily',
          ),
        ];

      case CollectionTemplateType.homeRenovation:
        return [
          _block(
            id: nextId(),
            collectionId: collectionId,
            typeKey: CollectionBlockType.section.key,
            title: 'Rooms',
            nowIso: nowIso,
            position: 0,
          ),
          _block(
            id: nextId(),
            collectionId: collectionId,
            typeKey: CollectionBlockType.checklist.key,
            title: 'Kitchen Remodel',
            nowIso: nowIso,
            position: 1,
            checklistItems: [
              CollectionChecklistItemRecordDto(
                id: nextCheckItemId(),
                title: 'Demo old countertops',
                isDone: false,
              ),
              CollectionChecklistItemRecordDto(
                id: nextCheckItemId(),
                title: 'Install new cabinets',
                isDone: false,
              ),
              CollectionChecklistItemRecordDto(
                id: nextCheckItemId(),
                title: 'Plumbing updates',
                isDone: false,
              ),
              CollectionChecklistItemRecordDto(
                id: nextCheckItemId(),
                title: 'Backsplash tile',
                isDone: false,
              ),
              CollectionChecklistItemRecordDto(
                id: nextCheckItemId(),
                title: 'Countertop installation',
                isDone: false,
              ),
            ],
          ),
          _block(
            id: nextId(),
            collectionId: collectionId,
            typeKey: CollectionBlockType.expense.key,
            title: 'Contractor Quote',
            nowIso: nowIso,
            position: 2,
            currencyCode: 'USD',
            amount: 15000,
          ),
          _block(
            id: nextId(),
            collectionId: collectionId,
            typeKey: CollectionBlockType.expense.key,
            title: 'Flooring Materials',
            nowIso: nowIso,
            position: 3,
            currencyCode: 'USD',
            amount: 3200,
          ),
          _block(
            id: nextId(),
            collectionId: collectionId,
            typeKey: CollectionBlockType.timeline.key,
            title: 'Renovation Timeline',
            nowIso: nowIso,
            position: 4,
            eventAtIso: DateTime(
              now.year,
              now.month,
              now.day,
              8,
            ).add(const Duration(days: 30)).toIso8601String(),
            locationLabel: 'Home',
          ),
          _block(
            id: nextId(),
            collectionId: collectionId,
            typeKey: CollectionBlockType.link.key,
            title: 'Inspiration Board',
            nowIso: nowIso,
            position: 5,
            url: 'https://www.pinterest.com',
            domainLabel: 'pinterest.com',
          ),
          _block(
            id: nextId(),
            collectionId: collectionId,
            typeKey: CollectionBlockType.reminder.key,
            title: 'Contractor follow-up',
            nowIso: nowIso,
            position: 6,
            eventAtIso: now.add(const Duration(days: 7)).toIso8601String(),
          ),
        ];

      case CollectionTemplateType.weddingPlanner:
        return [
          _block(
            id: nextId(),
            collectionId: collectionId,
            typeKey: CollectionBlockType.section.key,
            title: 'Vendors',
            nowIso: nowIso,
            position: 0,
          ),
          _block(
            id: nextId(),
            collectionId: collectionId,
            typeKey: CollectionBlockType.section.key,
            title: 'Guest List',
            nowIso: nowIso,
            position: 1,
          ),
          _block(
            id: nextId(),
            collectionId: collectionId,
            typeKey: CollectionBlockType.checklist.key,
            title: 'Wedding Day Checklist',
            nowIso: nowIso,
            position: 2,
            checklistItems: [
              CollectionChecklistItemRecordDto(
                id: nextCheckItemId(),
                title: 'Venue confirmed',
                isDone: false,
              ),
              CollectionChecklistItemRecordDto(
                id: nextCheckItemId(),
                title: 'Catering finalized',
                isDone: false,
              ),
              CollectionChecklistItemRecordDto(
                id: nextCheckItemId(),
                title: 'Photographer booked',
                isDone: false,
              ),
              CollectionChecklistItemRecordDto(
                id: nextCheckItemId(),
                title: 'Flowers ordered',
                isDone: false,
              ),
              CollectionChecklistItemRecordDto(
                id: nextCheckItemId(),
                title: 'DJ booked',
                isDone: false,
              ),
              CollectionChecklistItemRecordDto(
                id: nextCheckItemId(),
                title: 'Dress fitting',
                isDone: false,
              ),
            ],
          ),
          _block(
            id: nextId(),
            collectionId: collectionId,
            typeKey: CollectionBlockType.expense.key,
            title: 'Venue Deposit',
            nowIso: nowIso,
            position: 3,
            currencyCode: 'USD',
            amount: 5000,
          ),
          _block(
            id: nextId(),
            collectionId: collectionId,
            typeKey: CollectionBlockType.timeline.key,
            title: 'Ceremony',
            nowIso: nowIso,
            position: 4,
            eventAtIso: DateTime(
              now.year,
              now.month,
              now.day,
              15,
            ).add(const Duration(days: 90)).toIso8601String(),
            locationLabel: 'Rose Garden Estate',
          ),
          _block(
            id: nextId(),
            collectionId: collectionId,
            typeKey: CollectionBlockType.link.key,
            title: 'Wedding Inspiration',
            nowIso: nowIso,
            position: 5,
            url: 'https://www.theknot.com',
            domainLabel: 'theknot.com',
          ),
          _block(
            id: nextId(),
            collectionId: collectionId,
            typeKey: CollectionBlockType.note.key,
            title: 'Invitation Tracker',
            description:
                'Track RSVPs, dietary restrictions, and seating arrangements',
            nowIso: nowIso,
            position: 6,
          ),
          _block(
            id: nextId(),
            collectionId: collectionId,
            typeKey: CollectionBlockType.reminder.key,
            title: 'Send save-the-dates',
            nowIso: nowIso,
            position: 7,
            eventAtIso: now.add(const Duration(days: 60)).toIso8601String(),
          ),
        ];

      case CollectionTemplateType.freelanceTracker:
        // ── Pre-generate section IDs so children can reference them ──
        final project1Id = nextId();
        final project2Id = nextId();
        final paymentsId = nextId();
        final targetsId = nextId();
        final rhythmId = nextId();
        return [
          // ═══════════════════════════════════════════════════════════
          // PROJECT 1
          // ═══════════════════════════════════════════════════════════
          _block(
            id: project1Id,
            collectionId: collectionId,
            typeKey: CollectionBlockType.section.key,
            title: 'Project 1 — Client Name',
            description: 'Replace with your actual project & client',
            nowIso: nowIso,
            position: 0,
          ),
          _block(
            id: nextId(),
            collectionId: collectionId,
            parentBlockId: project1Id,
            typeKey: CollectionBlockType.input.key,
            title: 'Client',
            subtitle: 'e.g. Acme Corp',
            nowIso: nowIso,
            position: 0,
          ),
          _block(
            id: nextId(),
            collectionId: collectionId,
            parentBlockId: project1Id,
            typeKey: CollectionBlockType.input.key,
            title: 'Rate',
            subtitle: r'e.g. $90/hour or $3 500 fixed',
            nowIso: nowIso,
            position: 1,
          ),
          _block(
            id: nextId(),
            collectionId: collectionId,
            parentBlockId: project1Id,
            typeKey: CollectionBlockType.input.key,
            title: 'Status',
            subtitle: 'In Progress',
            nowIso: nowIso,
            position: 2,
          ),
          _block(
            id: nextId(),
            collectionId: collectionId,
            parentBlockId: project1Id,
            typeKey: CollectionBlockType.timeline.key,
            title: 'Deadline',
            nowIso: nowIso,
            position: 3,
            eventAtIso: now.add(const Duration(days: 30)).toIso8601String(),
          ),
          _block(
            id: nextId(),
            collectionId: collectionId,
            parentBlockId: project1Id,
            typeKey: CollectionBlockType.checklist.key,
            title: 'Milestones',
            nowIso: nowIso,
            position: 4,
            checklistItems: [
              CollectionChecklistItemRecordDto(
                id: nextCheckItemId(),
                title: 'Discovery & scope',
                isDone: false,
              ),
              CollectionChecklistItemRecordDto(
                id: nextCheckItemId(),
                title: 'First deliverable',
                isDone: false,
              ),
              CollectionChecklistItemRecordDto(
                id: nextCheckItemId(),
                title: 'Client review',
                isDone: false,
              ),
              CollectionChecklistItemRecordDto(
                id: nextCheckItemId(),
                title: 'Final delivery',
                isDone: false,
              ),
              CollectionChecklistItemRecordDto(
                id: nextCheckItemId(),
                title: 'Invoice sent',
                isDone: false,
              ),
            ],
          ),
          _block(
            id: nextId(),
            collectionId: collectionId,
            parentBlockId: project1Id,
            typeKey: CollectionBlockType.folder.key,
            title: 'Contracts & Documents',
            subtitle: '0 items',
            nowIso: nowIso,
            position: 5,
          ),
          _block(
            id: nextId(),
            collectionId: collectionId,
            parentBlockId: project1Id,
            typeKey: CollectionBlockType.note.key,
            title: 'Notes & Scope',
            description: 'Project brief, requirements, and scope notes',
            nowIso: nowIso,
            position: 6,
          ),

          // ═══════════════════════════════════════════════════════════
          // PROJECT 2
          // ═══════════════════════════════════════════════════════════
          _block(
            id: project2Id,
            collectionId: collectionId,
            typeKey: CollectionBlockType.section.key,
            title: 'Project 2 — Client Name',
            description: 'Duplicate this section for each new project',
            nowIso: nowIso,
            position: 1,
          ),
          _block(
            id: nextId(),
            collectionId: collectionId,
            parentBlockId: project2Id,
            typeKey: CollectionBlockType.input.key,
            title: 'Client',
            subtitle: 'e.g. Beta Studio',
            nowIso: nowIso,
            position: 0,
          ),
          _block(
            id: nextId(),
            collectionId: collectionId,
            parentBlockId: project2Id,
            typeKey: CollectionBlockType.input.key,
            title: 'Rate',
            subtitle: r'e.g. $75/hour or $2 000 fixed',
            nowIso: nowIso,
            position: 1,
          ),
          _block(
            id: nextId(),
            collectionId: collectionId,
            parentBlockId: project2Id,
            typeKey: CollectionBlockType.input.key,
            title: 'Status',
            subtitle: 'Negotiating',
            nowIso: nowIso,
            position: 2,
          ),
          _block(
            id: nextId(),
            collectionId: collectionId,
            parentBlockId: project2Id,
            typeKey: CollectionBlockType.timeline.key,
            title: 'Deadline',
            nowIso: nowIso,
            position: 3,
            eventAtIso: now.add(const Duration(days: 60)).toIso8601String(),
          ),
          _block(
            id: nextId(),
            collectionId: collectionId,
            parentBlockId: project2Id,
            typeKey: CollectionBlockType.checklist.key,
            title: 'Milestones',
            nowIso: nowIso,
            position: 4,
            checklistItems: [
              CollectionChecklistItemRecordDto(
                id: nextCheckItemId(),
                title: 'Discovery & scope',
                isDone: false,
              ),
              CollectionChecklistItemRecordDto(
                id: nextCheckItemId(),
                title: 'First deliverable',
                isDone: false,
              ),
              CollectionChecklistItemRecordDto(
                id: nextCheckItemId(),
                title: 'Client review',
                isDone: false,
              ),
              CollectionChecklistItemRecordDto(
                id: nextCheckItemId(),
                title: 'Final delivery',
                isDone: false,
              ),
              CollectionChecklistItemRecordDto(
                id: nextCheckItemId(),
                title: 'Invoice sent',
                isDone: false,
              ),
            ],
          ),
          _block(
            id: nextId(),
            collectionId: collectionId,
            parentBlockId: project2Id,
            typeKey: CollectionBlockType.folder.key,
            title: 'Contracts & Documents',
            subtitle: '0 items',
            nowIso: nowIso,
            position: 5,
          ),

          // ═══════════════════════════════════════════════════════════
          // PAYMENTS & INVOICING
          // ═══════════════════════════════════════════════════════════
          _block(
            id: paymentsId,
            collectionId: collectionId,
            typeKey: CollectionBlockType.section.key,
            title: 'Payments & Invoicing',
            nowIso: nowIso,
            position: 2,
          ),
          _block(
            id: nextId(),
            collectionId: collectionId,
            parentBlockId: paymentsId,
            typeKey: CollectionBlockType.checklist.key,
            title: 'Missing Payments',
            description: 'Track overdue and pending payments',
            nowIso: nowIso,
            position: 0,
            checklistItems: [
              CollectionChecklistItemRecordDto(
                id: nextCheckItemId(),
                title: 'Project 1 — Milestone 1 payment',
                isDone: false,
              ),
              CollectionChecklistItemRecordDto(
                id: nextCheckItemId(),
                title: 'Project 2 — Deposit payment',
                isDone: false,
              ),
            ],
          ),
          _block(
            id: nextId(),
            collectionId: collectionId,
            parentBlockId: paymentsId,
            typeKey: CollectionBlockType.expense.key,
            title: 'Total Received This Month',
            nowIso: nowIso,
            position: 1,
            currencyCode: 'EUR',
            amount: 0,
          ),
          _block(
            id: nextId(),
            collectionId: collectionId,
            parentBlockId: paymentsId,
            typeKey: CollectionBlockType.expense.key,
            title: 'Total Outstanding',
            nowIso: nowIso,
            position: 2,
            currencyCode: 'EUR',
            amount: 0,
          ),
          _block(
            id: nextId(),
            collectionId: collectionId,
            parentBlockId: paymentsId,
            typeKey: CollectionBlockType.reminder.key,
            title: 'Send invoices',
            nowIso: nowIso,
            position: 3,
            eventAtIso: DateTime(now.year, now.month + 1, 0).toIso8601String(),
            repeatInterval: 'monthly',
          ),
          _block(
            id: nextId(),
            collectionId: collectionId,
            parentBlockId: paymentsId,
            typeKey: CollectionBlockType.reminder.key,
            title: 'Follow up on unpaid invoices',
            nowIso: nowIso,
            position: 4,
            eventAtIso: now.add(const Duration(days: 7)).toIso8601String(),
            repeatInterval: 'weekly',
          ),

          // ═══════════════════════════════════════════════════════════
          // REVENUE TARGETS
          // ═══════════════════════════════════════════════════════════
          _block(
            id: targetsId,
            collectionId: collectionId,
            typeKey: CollectionBlockType.section.key,
            title: 'Revenue Targets',
            nowIso: nowIso,
            position: 3,
          ),
          _block(
            id: nextId(),
            collectionId: collectionId,
            parentBlockId: targetsId,
            typeKey: CollectionBlockType.progress.key,
            title: 'Monthly Revenue',
            subtitle: '0% complete',
            nowIso: nowIso,
            position: 0,
            amount: 0,
            metadata: const {'target_amount': '5000', 'unit': '€'},
          ),
          _block(
            id: nextId(),
            collectionId: collectionId,
            parentBlockId: targetsId,
            typeKey: CollectionBlockType.progress.key,
            title: 'Project 1 Payment',
            subtitle: '0% complete',
            description: 'Track payment progress for this project',
            nowIso: nowIso,
            position: 1,
            amount: 0,
            metadata: const {'target_amount': '2500', 'unit': '€'},
          ),
          _block(
            id: nextId(),
            collectionId: collectionId,
            parentBlockId: targetsId,
            typeKey: CollectionBlockType.input.key,
            title: 'Quarterly Goal',
            subtitle: r'e.g. €15 000',
            nowIso: nowIso,
            position: 2,
          ),
          _block(
            id: nextId(),
            collectionId: collectionId,
            parentBlockId: targetsId,
            typeKey: CollectionBlockType.note.key,
            title: 'Pipeline Notes',
            description: 'Upcoming leads, proposals sent, expected closes',
            nowIso: nowIso,
            position: 3,
          ),

          // ═══════════════════════════════════════════════════════════
          // KEEP THE RHYTHM
          // ═══════════════════════════════════════════════════════════
          _block(
            id: rhythmId,
            collectionId: collectionId,
            typeKey: CollectionBlockType.section.key,
            title: 'Keep the Rhythm',
            description: 'Weekly habits to stay on track',
            nowIso: nowIso,
            position: 4,
          ),
          _block(
            id: nextId(),
            collectionId: collectionId,
            parentBlockId: rhythmId,
            typeKey: CollectionBlockType.checklist.key,
            title: 'Weekly Review',
            description: 'Reset every Monday',
            nowIso: nowIso,
            position: 0,
            checklistItems: [
              CollectionChecklistItemRecordDto(
                id: nextCheckItemId(),
                title: 'Update project statuses',
                isDone: false,
              ),
              CollectionChecklistItemRecordDto(
                id: nextCheckItemId(),
                title: 'Log hours for each project',
                isDone: false,
              ),
              CollectionChecklistItemRecordDto(
                id: nextCheckItemId(),
                title: 'Check missing payments',
                isDone: false,
              ),
              CollectionChecklistItemRecordDto(
                id: nextCheckItemId(),
                title: 'Send any pending invoices',
                isDone: false,
              ),
              CollectionChecklistItemRecordDto(
                id: nextCheckItemId(),
                title: 'Plan next week deliverables',
                isDone: false,
              ),
            ],
          ),
          _block(
            id: nextId(),
            collectionId: collectionId,
            parentBlockId: rhythmId,
            typeKey: CollectionBlockType.reminder.key,
            title: 'Weekly review',
            nowIso: nowIso,
            position: 1,
            eventAtIso: now
                .add(Duration(days: DateTime.monday - now.weekday + 7))
                .toIso8601String(),
            repeatInterval: 'weekly',
          ),
          _block(
            id: nextId(),
            collectionId: collectionId,
            parentBlockId: rhythmId,
            typeKey: CollectionBlockType.reminder.key,
            title: 'Monthly revenue check',
            nowIso: nowIso,
            position: 2,
            eventAtIso: DateTime(now.year, now.month + 1, 1).toIso8601String(),
            repeatInterval: 'monthly',
          ),
          _block(
            id: nextId(),
            collectionId: collectionId,
            parentBlockId: rhythmId,
            typeKey: CollectionBlockType.link.key,
            title: 'Portfolio',
            nowIso: nowIso,
            position: 3,
            url: 'https://www.behance.net',
            domainLabel: 'behance.net',
          ),
        ];

      case CollectionTemplateType.diplomasCertificates:
        return [
          _block(
            id: nextId(),
            collectionId: collectionId,
            typeKey: CollectionBlockType.folder.key,
            title: 'Degrees',
            subtitle: '0 items',
            nowIso: nowIso,
            position: 0,
          ),
          _block(
            id: nextId(),
            collectionId: collectionId,
            typeKey: CollectionBlockType.folder.key,
            title: 'Professional Certifications',
            subtitle: '0 items',
            nowIso: nowIso,
            position: 1,
          ),
          _block(
            id: nextId(),
            collectionId: collectionId,
            typeKey: CollectionBlockType.checklist.key,
            title: 'Diploma Checklist',
            nowIso: nowIso,
            position: 2,
            checklistItems: [
              CollectionChecklistItemRecordDto(
                id: nextCheckItemId(),
                title: "Bachelor's degree",
                isDone: false,
              ),
              CollectionChecklistItemRecordDto(
                id: nextCheckItemId(),
                title: "Master's degree",
                isDone: false,
              ),
              CollectionChecklistItemRecordDto(
                id: nextCheckItemId(),
                title: 'Professional certification',
                isDone: false,
              ),
              CollectionChecklistItemRecordDto(
                id: nextCheckItemId(),
                title: 'Language certificate',
                isDone: false,
              ),
            ],
          ),
          _block(
            id: nextId(),
            collectionId: collectionId,
            typeKey: CollectionBlockType.note.key,
            title: 'Transcript',
            description: 'Academic transcripts and grade records',
            nowIso: nowIso,
            position: 3,
          ),
          _block(
            id: nextId(),
            collectionId: collectionId,
            typeKey: CollectionBlockType.timeline.key,
            title: 'Graduation Date',
            nowIso: nowIso,
            position: 4,
            eventAtIso: DateTime(
              now.year,
              now.month,
              now.day,
              10,
            ).add(const Duration(days: 180)).toIso8601String(),
            locationLabel: 'University',
          ),
          _block(
            id: nextId(),
            collectionId: collectionId,
            typeKey: CollectionBlockType.reminder.key,
            title: 'Diploma verification',
            nowIso: nowIso,
            position: 5,
            eventAtIso: now.add(const Duration(days: 30)).toIso8601String(),
          ),
        ];

      case CollectionTemplateType.bankDocuments:
        // Generate section IDs first so children can reference them.
        final primaryBankId = nextId();
        final secondaryBankId = nextId();
        final cardsLoansId = nextId();
        return [
          // ── Primary Bank ──
          _block(
            id: primaryBankId,
            collectionId: collectionId,
            typeKey: CollectionBlockType.section.key,
            title: 'Primary Bank',
            nowIso: nowIso,
            position: 0,
          ),
          _block(
            id: nextId(),
            collectionId: collectionId,
            parentBlockId: primaryBankId,
            typeKey: CollectionBlockType.input.key,
            title: 'Bank Name',
            subtitle: 'e.g. BNP Paribas',
            nowIso: nowIso,
            position: 0,
          ),
          _block(
            id: nextId(),
            collectionId: collectionId,
            parentBlockId: primaryBankId,
            typeKey: CollectionBlockType.input.key,
            title: 'RIB / IBAN',
            subtitle: 'FR76 XXXX XXXX XXXX XXXX XXXX XXX',
            nowIso: nowIso,
            position: 1,
          ),
          _block(
            id: nextId(),
            collectionId: collectionId,
            parentBlockId: primaryBankId,
            typeKey: CollectionBlockType.input.key,
            title: 'Account Number',
            subtitle: 'XXXX-XXXX-XXXX',
            nowIso: nowIso,
            position: 2,
          ),
          _block(
            id: nextId(),
            collectionId: collectionId,
            parentBlockId: primaryBankId,
            typeKey: CollectionBlockType.input.key,
            title: 'BIC / SWIFT Code',
            subtitle: 'BNPAFRPP',
            nowIso: nowIso,
            position: 3,
          ),
          _block(
            id: nextId(),
            collectionId: collectionId,
            parentBlockId: primaryBankId,
            typeKey: CollectionBlockType.folder.key,
            title: 'Statements & RIB Documents',
            subtitle: '0 items',
            nowIso: nowIso,
            position: 4,
          ),
          _block(
            id: nextId(),
            collectionId: collectionId,
            parentBlockId: primaryBankId,
            typeKey: CollectionBlockType.note.key,
            title: 'Bank Contact & Branch',
            subtitle: 'Agency address, phone, advisor name',
            nowIso: nowIso,
            position: 5,
          ),

          // ── Secondary Bank ──
          _block(
            id: secondaryBankId,
            collectionId: collectionId,
            typeKey: CollectionBlockType.section.key,
            title: 'Secondary Bank',
            nowIso: nowIso,
            position: 1,
          ),
          _block(
            id: nextId(),
            collectionId: collectionId,
            parentBlockId: secondaryBankId,
            typeKey: CollectionBlockType.input.key,
            title: 'Bank Name',
            subtitle: 'e.g. Société Générale',
            nowIso: nowIso,
            position: 0,
          ),
          _block(
            id: nextId(),
            collectionId: collectionId,
            parentBlockId: secondaryBankId,
            typeKey: CollectionBlockType.input.key,
            title: 'RIB / IBAN',
            subtitle: 'FR76 XXXX XXXX XXXX XXXX XXXX XXX',
            nowIso: nowIso,
            position: 1,
          ),
          _block(
            id: nextId(),
            collectionId: collectionId,
            parentBlockId: secondaryBankId,
            typeKey: CollectionBlockType.input.key,
            title: 'Account Number',
            subtitle: 'XXXX-XXXX-XXXX',
            nowIso: nowIso,
            position: 2,
          ),
          _block(
            id: nextId(),
            collectionId: collectionId,
            parentBlockId: secondaryBankId,
            typeKey: CollectionBlockType.input.key,
            title: 'BIC / SWIFT Code',
            subtitle: 'SOGEFRPP',
            nowIso: nowIso,
            position: 3,
          ),
          _block(
            id: nextId(),
            collectionId: collectionId,
            parentBlockId: secondaryBankId,
            typeKey: CollectionBlockType.folder.key,
            title: 'Statements & RIB Documents',
            subtitle: '0 items',
            nowIso: nowIso,
            position: 4,
          ),
          _block(
            id: nextId(),
            collectionId: collectionId,
            parentBlockId: secondaryBankId,
            typeKey: CollectionBlockType.note.key,
            title: 'Bank Contact & Branch',
            subtitle: 'Agency address, phone, advisor name',
            nowIso: nowIso,
            position: 5,
          ),

          // ── Highlights & Tracking ──
          _block(
            id: cardsLoansId,
            collectionId: collectionId,
            typeKey: CollectionBlockType.section.key,
            title: 'Cards & Loans',
            nowIso: nowIso,
            position: 2,
          ),
          _block(
            id: nextId(),
            collectionId: collectionId,
            parentBlockId: cardsLoansId,
            typeKey: CollectionBlockType.checklist.key,
            title: 'Credit / Debit Cards',
            nowIso: nowIso,
            position: 0,
            checklistItems: [
              CollectionChecklistItemRecordDto(
                id: nextCheckItemId(),
                title: 'Primary Visa — Expiry noted',
                isDone: false,
              ),
              CollectionChecklistItemRecordDto(
                id: nextCheckItemId(),
                title: 'Secondary Mastercard — Expiry noted',
                isDone: false,
              ),
              CollectionChecklistItemRecordDto(
                id: nextCheckItemId(),
                title: 'Card limits reviewed',
                isDone: false,
              ),
            ],
          ),
          _block(
            id: nextId(),
            collectionId: collectionId,
            parentBlockId: cardsLoansId,
            typeKey: CollectionBlockType.checklist.key,
            title: 'Active Loans & Subscriptions',
            nowIso: nowIso,
            position: 1,
            checklistItems: [
              CollectionChecklistItemRecordDto(
                id: nextCheckItemId(),
                title: 'Mortgage / Rent auto-debit verified',
                isDone: false,
              ),
              CollectionChecklistItemRecordDto(
                id: nextCheckItemId(),
                title: 'Insurance premiums auto-debit set',
                isDone: false,
              ),
              CollectionChecklistItemRecordDto(
                id: nextCheckItemId(),
                title: 'Standing orders reviewed',
                isDone: false,
              ),
            ],
          ),
          _block(
            id: nextId(),
            collectionId: collectionId,
            parentBlockId: cardsLoansId,
            typeKey: CollectionBlockType.folder.key,
            title: 'Loan Contracts & Offers',
            subtitle: '0 items',
            nowIso: nowIso,
            position: 2,
          ),
          _block(
            id: nextId(),
            collectionId: collectionId,
            parentBlockId: cardsLoansId,
            typeKey: CollectionBlockType.reminder.key,
            title: 'Annual bank fees review',
            nowIso: nowIso,
            position: 3,
            eventAtIso: DateTime(now.year + 1, 1, 15, 9).toIso8601String(),
            repeatInterval: 'yearly',
          ),
          _block(
            id: nextId(),
            collectionId: collectionId,
            parentBlockId: cardsLoansId,
            typeKey: CollectionBlockType.reminder.key,
            title: 'Card expiry check',
            nowIso: nowIso,
            position: 4,
            eventAtIso: now.add(const Duration(days: 180)).toIso8601String(),
            repeatInterval: 'biannual',
          ),
        ];

      case CollectionTemplateType.healthRecords:
        return [
          _block(
            id: nextId(),
            collectionId: collectionId,
            typeKey: CollectionBlockType.section.key,
            title: 'Medical History',
            nowIso: nowIso,
            position: 0,
          ),
          _block(
            id: nextId(),
            collectionId: collectionId,
            typeKey: CollectionBlockType.checklist.key,
            title: 'Vaccinations',
            nowIso: nowIso,
            position: 1,
            checklistItems: [
              CollectionChecklistItemRecordDto(
                id: nextCheckItemId(),
                title: 'COVID-19',
                isDone: false,
              ),
              CollectionChecklistItemRecordDto(
                id: nextCheckItemId(),
                title: 'Hepatitis B',
                isDone: false,
              ),
              CollectionChecklistItemRecordDto(
                id: nextCheckItemId(),
                title: 'Tetanus',
                isDone: false,
              ),
              CollectionChecklistItemRecordDto(
                id: nextCheckItemId(),
                title: 'Flu shot',
                isDone: false,
              ),
              CollectionChecklistItemRecordDto(
                id: nextCheckItemId(),
                title: 'Travel vaccines',
                isDone: false,
              ),
            ],
          ),
          _block(
            id: nextId(),
            collectionId: collectionId,
            typeKey: CollectionBlockType.input.key,
            title: 'Blood Type',
            subtitle: 'O+',
            nowIso: nowIso,
            position: 2,
          ),
          _block(
            id: nextId(),
            collectionId: collectionId,
            typeKey: CollectionBlockType.note.key,
            title: 'Allergies',
            description: 'List all known allergies, medications, and reactions',
            nowIso: nowIso,
            position: 3,
          ),
          _block(
            id: nextId(),
            collectionId: collectionId,
            typeKey: CollectionBlockType.expense.key,
            title: 'Doctor Visit',
            nowIso: nowIso,
            position: 4,
            currencyCode: 'USD',
            amount: 150,
          ),
          _block(
            id: nextId(),
            collectionId: collectionId,
            typeKey: CollectionBlockType.reminder.key,
            title: 'Annual checkup',
            nowIso: nowIso,
            position: 5,
            eventAtIso: now.add(const Duration(days: 365)).toIso8601String(),
          ),
          _block(
            id: nextId(),
            collectionId: collectionId,
            typeKey: CollectionBlockType.link.key,
            title: 'Health Insurance',
            nowIso: nowIso,
            position: 6,
            url: 'https://www.ameli.fr',
            domainLabel: 'ameli.fr',
          ),
        ];

      case CollectionTemplateType.taxDocuments:
        return [
          _block(
            id: nextId(),
            collectionId: collectionId,
            typeKey: CollectionBlockType.folder.key,
            title: 'Tax Returns',
            subtitle: '0 items',
            nowIso: nowIso,
            position: 0,
          ),
          _block(
            id: nextId(),
            collectionId: collectionId,
            typeKey: CollectionBlockType.folder.key,
            title: 'Receipts & Deductions',
            subtitle: '0 items',
            nowIso: nowIso,
            position: 1,
          ),
          _block(
            id: nextId(),
            collectionId: collectionId,
            typeKey: CollectionBlockType.input.key,
            title: 'Tax ID',
            subtitle: 'XXX-XX-XXXX',
            nowIso: nowIso,
            position: 2,
          ),
          _block(
            id: nextId(),
            collectionId: collectionId,
            typeKey: CollectionBlockType.input.key,
            title: 'Annual Income',
            subtitle: r'$0',
            nowIso: nowIso,
            position: 3,
          ),
          _block(
            id: nextId(),
            collectionId: collectionId,
            typeKey: CollectionBlockType.timeline.key,
            title: 'Tax Filing Deadline',
            nowIso: nowIso,
            position: 4,
            eventAtIso: DateTime(
              now.year,
              now.month,
              now.day,
              23,
              59,
            ).add(const Duration(days: 120)).toIso8601String(),
          ),
          _block(
            id: nextId(),
            collectionId: collectionId,
            typeKey: CollectionBlockType.reminder.key,
            title: 'File tax return',
            nowIso: nowIso,
            position: 5,
            eventAtIso: now.add(const Duration(days: 90)).toIso8601String(),
          ),
          _block(
            id: nextId(),
            collectionId: collectionId,
            typeKey: CollectionBlockType.link.key,
            title: 'Tax Portal',
            nowIso: nowIso,
            position: 6,
            url: 'https://www.impots.gouv.fr',
            domainLabel: 'impots.gouv.fr',
          ),
        ];

      case CollectionTemplateType.warrantyTracker:
        final activeWarrantiesId = nextId();
        final extendedWarrantiesId = nextId();
        final expiredClaimedId = nextId();
        return [
          // ── Active Warranties ──
          _block(
            id: activeWarrantiesId,
            collectionId: collectionId,
            typeKey: CollectionBlockType.section.key,
            title: 'Active Warranties',
            nowIso: nowIso,
            position: 0,
          ),
          _block(
            id: nextId(),
            collectionId: collectionId,
            parentBlockId: activeWarrantiesId,
            typeKey: CollectionBlockType.input.key,
            title: 'Product Name',
            subtitle: 'e.g. MacBook Pro 16"',
            nowIso: nowIso,
            position: 0,
          ),
          _block(
            id: nextId(),
            collectionId: collectionId,
            parentBlockId: activeWarrantiesId,
            typeKey: CollectionBlockType.input.key,
            title: 'Brand / Manufacturer',
            subtitle: 'e.g. Apple',
            nowIso: nowIso,
            position: 1,
          ),
          _block(
            id: nextId(),
            collectionId: collectionId,
            parentBlockId: activeWarrantiesId,
            typeKey: CollectionBlockType.input.key,
            title: 'Model / Serial Number',
            subtitle: 'e.g. FVFXM3...',
            nowIso: nowIso,
            position: 2,
          ),
          _block(
            id: nextId(),
            collectionId: collectionId,
            parentBlockId: activeWarrantiesId,
            typeKey: CollectionBlockType.input.key,
            title: 'Purchase Date',
            subtitle: 'MM/DD/YYYY',
            nowIso: nowIso,
            position: 3,
          ),
          _block(
            id: nextId(),
            collectionId: collectionId,
            parentBlockId: activeWarrantiesId,
            typeKey: CollectionBlockType.input.key,
            title: 'Purchase Price',
            subtitle: '0.00',
            nowIso: nowIso,
            position: 4,
          ),
          _block(
            id: nextId(),
            collectionId: collectionId,
            parentBlockId: activeWarrantiesId,
            typeKey: CollectionBlockType.input.key,
            title: 'Retailer / Store',
            subtitle: 'e.g. Apple Store',
            nowIso: nowIso,
            position: 5,
          ),
          _block(
            id: nextId(),
            collectionId: collectionId,
            parentBlockId: activeWarrantiesId,
            typeKey: CollectionBlockType.input.key,
            title: 'Warranty Type',
            subtitle: 'Standard / Extended / AppleCare',
            nowIso: nowIso,
            position: 6,
          ),
          _block(
            id: nextId(),
            collectionId: collectionId,
            parentBlockId: activeWarrantiesId,
            typeKey: CollectionBlockType.reminder.key,
            title: 'Warranty Expiry',
            nowIso: nowIso,
            position: 7,
            eventAtIso: now.add(const Duration(days: 90)).toIso8601String(),
          ),
          _block(
            id: nextId(),
            collectionId: collectionId,
            parentBlockId: activeWarrantiesId,
            typeKey: CollectionBlockType.folder.key,
            title: 'Receipts & Proof of Purchase',
            subtitle: '0 items',
            nowIso: nowIso,
            position: 8,
          ),
          _block(
            id: nextId(),
            collectionId: collectionId,
            parentBlockId: activeWarrantiesId,
            typeKey: CollectionBlockType.note.key,
            title: 'Claim Instructions',
            subtitle: 'How to file a warranty claim',
            nowIso: nowIso,
            position: 9,
          ),

          // ── Extended Warranties ──
          _block(
            id: extendedWarrantiesId,
            collectionId: collectionId,
            typeKey: CollectionBlockType.section.key,
            title: 'Extended Warranties',
            nowIso: nowIso,
            position: 1,
          ),
          _block(
            id: nextId(),
            collectionId: collectionId,
            parentBlockId: extendedWarrantiesId,
            typeKey: CollectionBlockType.input.key,
            title: 'Provider',
            subtitle: 'e.g. SquareTrade',
            nowIso: nowIso,
            position: 0,
          ),
          _block(
            id: nextId(),
            collectionId: collectionId,
            parentBlockId: extendedWarrantiesId,
            typeKey: CollectionBlockType.input.key,
            title: 'Policy Number',
            subtitle: 'e.g. ST-123456',
            nowIso: nowIso,
            position: 1,
          ),
          _block(
            id: nextId(),
            collectionId: collectionId,
            parentBlockId: extendedWarrantiesId,
            typeKey: CollectionBlockType.input.key,
            title: 'Coverage Period',
            subtitle: 'Start - End dates',
            nowIso: nowIso,
            position: 2,
          ),
          _block(
            id: nextId(),
            collectionId: collectionId,
            parentBlockId: extendedWarrantiesId,
            typeKey: CollectionBlockType.input.key,
            title: 'Phone / Contact',
            subtitle: 'Support hotline',
            nowIso: nowIso,
            position: 3,
          ),
          _block(
            id: nextId(),
            collectionId: collectionId,
            parentBlockId: extendedWarrantiesId,
            typeKey: CollectionBlockType.folder.key,
            title: 'Extended Warranty Documents',
            subtitle: '0 items',
            nowIso: nowIso,
            position: 4,
          ),

          // ── Expired / Claimed ──
          _block(
            id: expiredClaimedId,
            collectionId: collectionId,
            typeKey: CollectionBlockType.section.key,
            title: 'Expired / Claimed',
            nowIso: nowIso,
            position: 2,
          ),
          _block(
            id: nextId(),
            collectionId: collectionId,
            parentBlockId: expiredClaimedId,
            typeKey: CollectionBlockType.note.key,
            title: 'Archive',
            subtitle: 'Move expired warranties here',
            nowIso: nowIso,
            position: 0,
          ),
        ];

      case CollectionTemplateType.subscriptionManager:
        final activeSubsId = nextId();
        final entertainmentId = nextId();
        final productivityId = nextId();
        final healthFitnessId = nextId();
        final pausedCancelledId = nextId();
        return [
          // ── Active Subscriptions ──
          _block(
            id: activeSubsId,
            collectionId: collectionId,
            typeKey: CollectionBlockType.section.key,
            title: 'Active Subscriptions',
            nowIso: nowIso,
            position: 0,
          ),
          _block(
            id: nextId(),
            collectionId: collectionId,
            parentBlockId: activeSubsId,
            typeKey: CollectionBlockType.input.key,
            title: 'Service Name',
            subtitle: 'e.g. Netflix',
            nowIso: nowIso,
            position: 0,
          ),
          _block(
            id: nextId(),
            collectionId: collectionId,
            parentBlockId: activeSubsId,
            typeKey: CollectionBlockType.input.key,
            title: 'Plan / Tier',
            subtitle: 'e.g. Premium 4K',
            nowIso: nowIso,
            position: 1,
          ),
          _block(
            id: nextId(),
            collectionId: collectionId,
            parentBlockId: activeSubsId,
            typeKey: CollectionBlockType.input.key,
            title: 'Monthly Cost',
            subtitle: '0.00',
            nowIso: nowIso,
            position: 2,
          ),
          _block(
            id: nextId(),
            collectionId: collectionId,
            parentBlockId: activeSubsId,
            typeKey: CollectionBlockType.input.key,
            title: 'Billing Cycle',
            subtitle: 'Monthly / Yearly / Quarterly',
            nowIso: nowIso,
            position: 3,
          ),
          _block(
            id: nextId(),
            collectionId: collectionId,
            parentBlockId: activeSubsId,
            typeKey: CollectionBlockType.input.key,
            title: 'Next Billing Date',
            subtitle: 'MM/DD/YYYY',
            nowIso: nowIso,
            position: 4,
          ),
          _block(
            id: nextId(),
            collectionId: collectionId,
            parentBlockId: activeSubsId,
            typeKey: CollectionBlockType.input.key,
            title: 'Payment Method',
            subtitle: 'e.g. Visa \u2022\u2022\u2022\u2022 4242',
            nowIso: nowIso,
            position: 5,
          ),
          _block(
            id: nextId(),
            collectionId: collectionId,
            parentBlockId: activeSubsId,
            typeKey: CollectionBlockType.input.key,
            title: 'Account Email',
            subtitle: 'login email',
            nowIso: nowIso,
            position: 6,
          ),
          _block(
            id: nextId(),
            collectionId: collectionId,
            parentBlockId: activeSubsId,
            typeKey: CollectionBlockType.link.key,
            title: 'Cancellation Link',
            subtitle: 'Direct link to cancel',
            nowIso: nowIso,
            position: 7,
          ),
          _block(
            id: nextId(),
            collectionId: collectionId,
            parentBlockId: activeSubsId,
            typeKey: CollectionBlockType.reminder.key,
            title: 'Renewal Reminder',
            nowIso: nowIso,
            position: 8,
            eventAtIso: now.add(const Duration(days: 30)).toIso8601String(),
            repeatInterval: 'monthly',
          ),
          _block(
            id: nextId(),
            collectionId: collectionId,
            parentBlockId: activeSubsId,
            typeKey: CollectionBlockType.note.key,
            title: 'Notes',
            subtitle: 'Family sharing, promo codes, etc.',
            nowIso: nowIso,
            position: 9,
          ),

          // ── Entertainment ──
          _block(
            id: entertainmentId,
            collectionId: collectionId,
            typeKey: CollectionBlockType.section.key,
            title: 'Entertainment',
            nowIso: nowIso,
            position: 1,
          ),
          _block(
            id: nextId(),
            collectionId: collectionId,
            parentBlockId: entertainmentId,
            typeKey: CollectionBlockType.input.key,
            title: 'Netflix',
            subtitle: '\u20AC15.99/mo',
            nowIso: nowIso,
            position: 0,
          ),
          _block(
            id: nextId(),
            collectionId: collectionId,
            parentBlockId: entertainmentId,
            typeKey: CollectionBlockType.input.key,
            title: 'Spotify',
            subtitle: '\u20AC10.99/mo',
            nowIso: nowIso,
            position: 1,
          ),
          _block(
            id: nextId(),
            collectionId: collectionId,
            parentBlockId: entertainmentId,
            typeKey: CollectionBlockType.input.key,
            title: 'YouTube Premium',
            subtitle: '\u20AC12.99/mo',
            nowIso: nowIso,
            position: 2,
          ),

          // ── Productivity & Cloud ──
          _block(
            id: productivityId,
            collectionId: collectionId,
            typeKey: CollectionBlockType.section.key,
            title: 'Productivity & Cloud',
            nowIso: nowIso,
            position: 2,
          ),
          _block(
            id: nextId(),
            collectionId: collectionId,
            parentBlockId: productivityId,
            typeKey: CollectionBlockType.input.key,
            title: 'iCloud+',
            subtitle: '\u20AC2.99/mo',
            nowIso: nowIso,
            position: 0,
          ),
          _block(
            id: nextId(),
            collectionId: collectionId,
            parentBlockId: productivityId,
            typeKey: CollectionBlockType.input.key,
            title: 'Google One',
            subtitle: '\u20AC1.99/mo',
            nowIso: nowIso,
            position: 1,
          ),
          _block(
            id: nextId(),
            collectionId: collectionId,
            parentBlockId: productivityId,
            typeKey: CollectionBlockType.input.key,
            title: 'Microsoft 365',
            subtitle: '\u20AC9.99/mo',
            nowIso: nowIso,
            position: 2,
          ),

          // ── Health & Fitness ──
          _block(
            id: healthFitnessId,
            collectionId: collectionId,
            typeKey: CollectionBlockType.section.key,
            title: 'Health & Fitness',
            nowIso: nowIso,
            position: 3,
          ),
          _block(
            id: nextId(),
            collectionId: collectionId,
            parentBlockId: healthFitnessId,
            typeKey: CollectionBlockType.input.key,
            title: 'Gym Membership',
            subtitle: '\u20AC49.90/mo',
            nowIso: nowIso,
            position: 0,
          ),

          // ── Paused / Cancelled ──
          _block(
            id: pausedCancelledId,
            collectionId: collectionId,
            typeKey: CollectionBlockType.section.key,
            title: 'Paused / Cancelled',
            nowIso: nowIso,
            position: 4,
          ),
          _block(
            id: nextId(),
            collectionId: collectionId,
            parentBlockId: pausedCancelledId,
            typeKey: CollectionBlockType.note.key,
            title: 'Archive',
            subtitle: 'Cancelled subscriptions for reference',
            nowIso: nowIso,
            position: 0,
          ),
        ];

      case CollectionTemplateType.homeMaintenance:
        final appliancesId = nextId();
        final serviceContactsId = nextId();
        final annualInspectionsId = nextId();
        final repairsHistoryId = nextId();
        final utilityProvidersId = nextId();
        final homeImprovementId = nextId();
        return [
          // ── Appliances & Equipment ──
          _block(
            id: appliancesId,
            collectionId: collectionId,
            typeKey: CollectionBlockType.section.key,
            title: 'Appliances & Equipment',
            nowIso: nowIso,
            position: 0,
          ),
          _block(
            id: nextId(),
            collectionId: collectionId,
            parentBlockId: appliancesId,
            typeKey: CollectionBlockType.input.key,
            title: 'Appliance Name',
            subtitle: 'e.g. Washing Machine',
            nowIso: nowIso,
            position: 0,
          ),
          _block(
            id: nextId(),
            collectionId: collectionId,
            parentBlockId: appliancesId,
            typeKey: CollectionBlockType.input.key,
            title: 'Brand / Model',
            subtitle: 'e.g. Samsung WW90...',
            nowIso: nowIso,
            position: 1,
          ),
          _block(
            id: nextId(),
            collectionId: collectionId,
            parentBlockId: appliancesId,
            typeKey: CollectionBlockType.input.key,
            title: 'Serial Number',
            subtitle: 'S/N for service calls',
            nowIso: nowIso,
            position: 2,
          ),
          _block(
            id: nextId(),
            collectionId: collectionId,
            parentBlockId: appliancesId,
            typeKey: CollectionBlockType.input.key,
            title: 'Purchase Date',
            subtitle: 'MM/DD/YYYY',
            nowIso: nowIso,
            position: 3,
          ),
          _block(
            id: nextId(),
            collectionId: collectionId,
            parentBlockId: appliancesId,
            typeKey: CollectionBlockType.input.key,
            title: 'Warranty Until',
            subtitle: 'MM/DD/YYYY',
            nowIso: nowIso,
            position: 4,
          ),
          _block(
            id: nextId(),
            collectionId: collectionId,
            parentBlockId: appliancesId,
            typeKey: CollectionBlockType.folder.key,
            title: 'Manuals & Receipts',
            subtitle: '0 items',
            nowIso: nowIso,
            position: 5,
          ),

          // ── Service Contacts ──
          _block(
            id: serviceContactsId,
            collectionId: collectionId,
            typeKey: CollectionBlockType.section.key,
            title: 'Service Contacts',
            nowIso: nowIso,
            position: 1,
          ),
          _block(
            id: nextId(),
            collectionId: collectionId,
            parentBlockId: serviceContactsId,
            typeKey: CollectionBlockType.input.key,
            title: 'Plumber',
            subtitle: 'Name, phone, notes',
            nowIso: nowIso,
            position: 0,
          ),
          _block(
            id: nextId(),
            collectionId: collectionId,
            parentBlockId: serviceContactsId,
            typeKey: CollectionBlockType.input.key,
            title: 'Electrician',
            subtitle: 'Name, phone, notes',
            nowIso: nowIso,
            position: 1,
          ),
          _block(
            id: nextId(),
            collectionId: collectionId,
            parentBlockId: serviceContactsId,
            typeKey: CollectionBlockType.input.key,
            title: 'HVAC Technician',
            subtitle: 'Name, phone, notes',
            nowIso: nowIso,
            position: 2,
          ),
          _block(
            id: nextId(),
            collectionId: collectionId,
            parentBlockId: serviceContactsId,
            typeKey: CollectionBlockType.input.key,
            title: 'Locksmith',
            subtitle: 'Name, phone, notes',
            nowIso: nowIso,
            position: 3,
          ),
          _block(
            id: nextId(),
            collectionId: collectionId,
            parentBlockId: serviceContactsId,
            typeKey: CollectionBlockType.input.key,
            title: 'General Contractor',
            subtitle: 'Name, phone, notes',
            nowIso: nowIso,
            position: 4,
          ),
          _block(
            id: nextId(),
            collectionId: collectionId,
            parentBlockId: serviceContactsId,
            typeKey: CollectionBlockType.input.key,
            title: 'Gardener / Landscaping',
            subtitle: 'Name, phone, notes',
            nowIso: nowIso,
            position: 5,
          ),
          _block(
            id: nextId(),
            collectionId: collectionId,
            parentBlockId: serviceContactsId,
            typeKey: CollectionBlockType.input.key,
            title: 'Pest Control',
            subtitle: 'Name, phone, notes',
            nowIso: nowIso,
            position: 6,
          ),
          _block(
            id: nextId(),
            collectionId: collectionId,
            parentBlockId: serviceContactsId,
            typeKey: CollectionBlockType.input.key,
            title: 'Cleaning Service',
            subtitle: 'Name, phone, notes',
            nowIso: nowIso,
            position: 7,
          ),

          // ── Annual Inspections ──
          _block(
            id: annualInspectionsId,
            collectionId: collectionId,
            typeKey: CollectionBlockType.section.key,
            title: 'Annual Inspections',
            nowIso: nowIso,
            position: 2,
          ),
          _block(
            id: nextId(),
            collectionId: collectionId,
            parentBlockId: annualInspectionsId,
            typeKey: CollectionBlockType.reminder.key,
            title: 'Boiler / Heating Service',
            nowIso: nowIso,
            position: 0,
            eventAtIso: now.add(const Duration(days: 365)).toIso8601String(),
            repeatInterval: 'yearly',
          ),
          _block(
            id: nextId(),
            collectionId: collectionId,
            parentBlockId: annualInspectionsId,
            typeKey: CollectionBlockType.reminder.key,
            title: 'Chimney Sweep',
            nowIso: nowIso,
            position: 1,
            eventAtIso: now.add(const Duration(days: 365)).toIso8601String(),
          ),
          _block(
            id: nextId(),
            collectionId: collectionId,
            parentBlockId: annualInspectionsId,
            typeKey: CollectionBlockType.reminder.key,
            title: 'Fire Extinguisher Check',
            nowIso: nowIso,
            position: 2,
            eventAtIso: now.add(const Duration(days: 365)).toIso8601String(),
          ),
          _block(
            id: nextId(),
            collectionId: collectionId,
            parentBlockId: annualInspectionsId,
            typeKey: CollectionBlockType.reminder.key,
            title: 'Smoke Detector Battery',
            nowIso: nowIso,
            position: 3,
            eventAtIso: now.add(const Duration(days: 180)).toIso8601String(),
          ),
          _block(
            id: nextId(),
            collectionId: collectionId,
            parentBlockId: annualInspectionsId,
            typeKey: CollectionBlockType.reminder.key,
            title: 'Roof Inspection',
            nowIso: nowIso,
            position: 4,
            eventAtIso: now.add(const Duration(days: 365)).toIso8601String(),
          ),
          _block(
            id: nextId(),
            collectionId: collectionId,
            parentBlockId: annualInspectionsId,
            typeKey: CollectionBlockType.reminder.key,
            title: 'Gutter Cleaning',
            nowIso: nowIso,
            position: 5,
            eventAtIso: now.add(const Duration(days: 180)).toIso8601String(),
          ),
          _block(
            id: nextId(),
            collectionId: collectionId,
            parentBlockId: annualInspectionsId,
            typeKey: CollectionBlockType.folder.key,
            title: 'Inspection Reports',
            subtitle: '0 items',
            nowIso: nowIso,
            position: 6,
          ),

          // ── Repairs & History ──
          _block(
            id: repairsHistoryId,
            collectionId: collectionId,
            typeKey: CollectionBlockType.section.key,
            title: 'Repairs & History',
            nowIso: nowIso,
            position: 3,
          ),
          _block(
            id: nextId(),
            collectionId: collectionId,
            parentBlockId: repairsHistoryId,
            typeKey: CollectionBlockType.note.key,
            title: 'Repair Log',
            subtitle: 'Date, issue, cost, who fixed it',
            nowIso: nowIso,
            position: 0,
          ),
          _block(
            id: nextId(),
            collectionId: collectionId,
            parentBlockId: repairsHistoryId,
            typeKey: CollectionBlockType.folder.key,
            title: 'Repair Invoices',
            subtitle: '0 items',
            nowIso: nowIso,
            position: 1,
          ),

          // ── Utility Providers ──
          _block(
            id: utilityProvidersId,
            collectionId: collectionId,
            typeKey: CollectionBlockType.section.key,
            title: 'Utility Providers',
            nowIso: nowIso,
            position: 4,
          ),
          _block(
            id: nextId(),
            collectionId: collectionId,
            parentBlockId: utilityProvidersId,
            typeKey: CollectionBlockType.input.key,
            title: 'Electricity',
            subtitle: 'Provider, account #, contact',
            nowIso: nowIso,
            position: 0,
          ),
          _block(
            id: nextId(),
            collectionId: collectionId,
            parentBlockId: utilityProvidersId,
            typeKey: CollectionBlockType.input.key,
            title: 'Gas',
            subtitle: 'Provider, account #, contact',
            nowIso: nowIso,
            position: 1,
          ),
          _block(
            id: nextId(),
            collectionId: collectionId,
            parentBlockId: utilityProvidersId,
            typeKey: CollectionBlockType.input.key,
            title: 'Water',
            subtitle: 'Provider, account #, contact',
            nowIso: nowIso,
            position: 2,
          ),
          _block(
            id: nextId(),
            collectionId: collectionId,
            parentBlockId: utilityProvidersId,
            typeKey: CollectionBlockType.input.key,
            title: 'Internet',
            subtitle: 'Provider, account #, contact',
            nowIso: nowIso,
            position: 3,
          ),
          _block(
            id: nextId(),
            collectionId: collectionId,
            parentBlockId: utilityProvidersId,
            typeKey: CollectionBlockType.input.key,
            title: 'Home Insurance',
            subtitle: 'Policy #, contact, renewal date',
            nowIso: nowIso,
            position: 4,
          ),
          _block(
            id: nextId(),
            collectionId: collectionId,
            parentBlockId: utilityProvidersId,
            typeKey: CollectionBlockType.folder.key,
            title: 'Utility Bills & Contracts',
            subtitle: '0 items',
            nowIso: nowIso,
            position: 5,
          ),

          // ── Home Improvement Projects ──
          _block(
            id: homeImprovementId,
            collectionId: collectionId,
            typeKey: CollectionBlockType.section.key,
            title: 'Home Improvement Projects',
            nowIso: nowIso,
            position: 5,
          ),
          _block(
            id: nextId(),
            collectionId: collectionId,
            parentBlockId: homeImprovementId,
            typeKey: CollectionBlockType.checklist.key,
            title: 'Current Projects',
            nowIso: nowIso,
            position: 0,
            checklistItems: [
              CollectionChecklistItemRecordDto(
                id: nextCheckItemId(),
                title: 'Kitchen renovation',
                isDone: false,
              ),
              CollectionChecklistItemRecordDto(
                id: nextCheckItemId(),
                title: 'Bathroom tiles',
                isDone: false,
              ),
              CollectionChecklistItemRecordDto(
                id: nextCheckItemId(),
                title: 'Garden fence',
                isDone: false,
              ),
              CollectionChecklistItemRecordDto(
                id: nextCheckItemId(),
                title: 'Paint bedroom',
                isDone: false,
              ),
            ],
          ),
          _block(
            id: nextId(),
            collectionId: collectionId,
            parentBlockId: homeImprovementId,
            typeKey: CollectionBlockType.input.key,
            title: 'Budget',
            subtitle: 'Total allocated',
            nowIso: nowIso,
            position: 1,
          ),
          _block(
            id: nextId(),
            collectionId: collectionId,
            parentBlockId: homeImprovementId,
            typeKey: CollectionBlockType.folder.key,
            title: 'Quotes & Plans',
            subtitle: '0 items',
            nowIso: nowIso,
            position: 2,
          ),
        ];

      case CollectionTemplateType.movieLibrary:
        final watchlistId = nextId();
        final watchedId = nextId();
        final favoritesId = nextId();
        return [
          // ── Watchlist ──
          _block(
            id: watchlistId,
            collectionId: collectionId,
            typeKey: CollectionBlockType.section.key,
            title: 'Watchlist',
            nowIso: nowIso,
            position: 0,
          ),
          _block(
            id: nextId(),
            collectionId: collectionId,
            parentBlockId: watchlistId,
            typeKey: CollectionBlockType.checklist.key,
            title: 'To Watch',
            nowIso: nowIso,
            position: 0,
            checklistItems: [
              CollectionChecklistItemRecordDto(
                id: nextCheckItemId(),
                title: 'Add movies you want to see',
                isDone: false,
              ),
            ],
          ),
          _block(
            id: nextId(),
            collectionId: collectionId,
            parentBlockId: watchlistId,
            typeKey: CollectionBlockType.input.key,
            title: 'Title',
            subtitle: 'Movie name',
            nowIso: nowIso,
            position: 1,
          ),
          _block(
            id: nextId(),
            collectionId: collectionId,
            parentBlockId: watchlistId,
            typeKey: CollectionBlockType.input.key,
            title: 'Director',
            subtitle: 'Director name',
            nowIso: nowIso,
            position: 2,
          ),
          _block(
            id: nextId(),
            collectionId: collectionId,
            parentBlockId: watchlistId,
            typeKey: CollectionBlockType.input.key,
            title: 'Year',
            subtitle: 'Release year',
            nowIso: nowIso,
            position: 3,
          ),
          _block(
            id: nextId(),
            collectionId: collectionId,
            parentBlockId: watchlistId,
            typeKey: CollectionBlockType.input.key,
            title: 'Genre',
            subtitle: 'e.g. Drama, Thriller, Comedy',
            nowIso: nowIso,
            position: 4,
          ),
          _block(
            id: nextId(),
            collectionId: collectionId,
            parentBlockId: watchlistId,
            typeKey: CollectionBlockType.input.key,
            title: 'Platform',
            subtitle: 'Netflix, Cinema, Prime, etc.',
            nowIso: nowIso,
            position: 5,
          ),

          // ── Watched ──
          _block(
            id: watchedId,
            collectionId: collectionId,
            typeKey: CollectionBlockType.section.key,
            title: 'Watched',
            nowIso: nowIso,
            position: 1,
          ),
          _block(
            id: nextId(),
            collectionId: collectionId,
            parentBlockId: watchedId,
            typeKey: CollectionBlockType.input.key,
            title: 'Rating',
            subtitle: 'Your score out of 10',
            nowIso: nowIso,
            position: 0,
          ),
          _block(
            id: nextId(),
            collectionId: collectionId,
            parentBlockId: watchedId,
            typeKey: CollectionBlockType.note.key,
            title: 'Notes & Reviews',
            description:
                'Write your thoughts, favourite scenes, or quotes from movies you\'ve watched.',
            nowIso: nowIso,
            position: 1,
          ),
          _block(
            id: nextId(),
            collectionId: collectionId,
            parentBlockId: watchedId,
            typeKey: CollectionBlockType.checklist.key,
            title: 'Recently Watched',
            nowIso: nowIso,
            position: 2,
            checklistItems: [
              CollectionChecklistItemRecordDto(
                id: nextCheckItemId(),
                title: 'Add your recently watched films',
                isDone: false,
              ),
            ],
          ),
          _block(
            id: nextId(),
            collectionId: collectionId,
            parentBlockId: watchedId,
            typeKey: CollectionBlockType.progress.key,
            title: 'Yearly Goal',
            description: 'Track how many movies you\'ve watched this year',
            nowIso: nowIso,
            position: 3,
          ),

          // ── Favorites ──
          _block(
            id: favoritesId,
            collectionId: collectionId,
            typeKey: CollectionBlockType.section.key,
            title: 'Favorites',
            nowIso: nowIso,
            position: 2,
          ),
          _block(
            id: nextId(),
            collectionId: collectionId,
            parentBlockId: favoritesId,
            typeKey: CollectionBlockType.folder.key,
            title: 'All-Time Favorites',
            subtitle: '0 items',
            nowIso: nowIso,
            position: 0,
          ),
          _block(
            id: nextId(),
            collectionId: collectionId,
            parentBlockId: favoritesId,
            typeKey: CollectionBlockType.link.key,
            title: 'Letterboxd / IMDb Profile',
            nowIso: nowIso,
            position: 1,
            url: '',
          ),
          _block(
            id: nextId(),
            collectionId: collectionId,
            parentBlockId: favoritesId,
            typeKey: CollectionBlockType.reminder.key,
            title: 'Movie night',
            nowIso: nowIso,
            position: 2,
            eventAtIso: now.add(const Duration(days: 7)).toIso8601String(),
          ),
        ];

      case CollectionTemplateType.readingList:
        final currentlyReadingId = nextId();
        final toReadId = nextId();
        final finishedId = nextId();
        return [
          // ── Currently Reading ──
          _block(
            id: currentlyReadingId,
            collectionId: collectionId,
            typeKey: CollectionBlockType.section.key,
            title: 'Currently Reading',
            nowIso: nowIso,
            position: 0,
          ),
          _block(
            id: nextId(),
            collectionId: collectionId,
            parentBlockId: currentlyReadingId,
            typeKey: CollectionBlockType.input.key,
            title: 'Title',
            subtitle: 'Book title',
            nowIso: nowIso,
            position: 0,
          ),
          _block(
            id: nextId(),
            collectionId: collectionId,
            parentBlockId: currentlyReadingId,
            typeKey: CollectionBlockType.input.key,
            title: 'Author',
            subtitle: 'Author name',
            nowIso: nowIso,
            position: 1,
          ),
          _block(
            id: nextId(),
            collectionId: collectionId,
            parentBlockId: currentlyReadingId,
            typeKey: CollectionBlockType.input.key,
            title: 'Genre',
            subtitle: 'e.g. Fiction, Mystery, Romance',
            nowIso: nowIso,
            position: 2,
          ),
          _block(
            id: nextId(),
            collectionId: collectionId,
            parentBlockId: currentlyReadingId,
            typeKey: CollectionBlockType.progress.key,
            title: 'Reading Progress',
            description: 'Track your progress through the book',
            nowIso: nowIso,
            position: 3,
          ),

          // ── To Read ──
          _block(
            id: toReadId,
            collectionId: collectionId,
            typeKey: CollectionBlockType.section.key,
            title: 'To Read',
            nowIso: nowIso,
            position: 1,
          ),
          _block(
            id: nextId(),
            collectionId: collectionId,
            parentBlockId: toReadId,
            typeKey: CollectionBlockType.checklist.key,
            title: 'To Read List',
            nowIso: nowIso,
            position: 0,
            checklistItems: [
              CollectionChecklistItemRecordDto(
                id: nextCheckItemId(),
                title: 'Add books you want to read',
                isDone: false,
              ),
            ],
          ),
          _block(
            id: nextId(),
            collectionId: collectionId,
            parentBlockId: toReadId,
            typeKey: CollectionBlockType.input.key,
            title: 'ISBN',
            subtitle: 'International Standard Book Number',
            nowIso: nowIso,
            position: 1,
          ),

          // ── Finished ──
          _block(
            id: finishedId,
            collectionId: collectionId,
            typeKey: CollectionBlockType.section.key,
            title: 'Finished',
            nowIso: nowIso,
            position: 2,
          ),
          _block(
            id: nextId(),
            collectionId: collectionId,
            parentBlockId: finishedId,
            typeKey: CollectionBlockType.note.key,
            title: 'Reviews & Notes',
            description: 'Write your thoughts and favorite quotes',
            nowIso: nowIso,
            position: 0,
          ),
          _block(
            id: nextId(),
            collectionId: collectionId,
            parentBlockId: finishedId,
            typeKey: CollectionBlockType.folder.key,
            title: 'Book Photos',
            subtitle: '0 items',
            nowIso: nowIso,
            position: 1,
          ),
          _block(
            id: nextId(),
            collectionId: collectionId,
            parentBlockId: finishedId,
            typeKey: CollectionBlockType.input.key,
            title: 'Rating',
            subtitle: 'Your score out of 5',
            nowIso: nowIso,
            position: 2,
          ),
          _block(
            id: nextId(),
            collectionId: collectionId,
            typeKey: CollectionBlockType.reminder.key,
            title: 'Next book club meeting',
            nowIso: nowIso,
            position: 3,
            eventAtIso: now.add(const Duration(days: 30)).toIso8601String(),
          ),
          _block(
            id: nextId(),
            collectionId: collectionId,
            typeKey: CollectionBlockType.link.key,
            title: 'Goodreads Profile',
            nowIso: nowIso,
            position: 4,
            url: '',
          ),
        ];

      case CollectionTemplateType.wineCellar:
        final collectionId_ = nextId();
        final tastingId = nextId();
        final wishlistId = nextId();
        return [
          // ── Collection ──
          _block(
            id: collectionId_,
            collectionId: collectionId,
            typeKey: CollectionBlockType.section.key,
            title: 'Collection',
            nowIso: nowIso,
            position: 0,
          ),
          _block(
            id: nextId(),
            collectionId: collectionId,
            parentBlockId: collectionId_,
            typeKey: CollectionBlockType.input.key,
            title: 'Name',
            subtitle: 'Wine name',
            nowIso: nowIso,
            position: 0,
          ),
          _block(
            id: nextId(),
            collectionId: collectionId,
            parentBlockId: collectionId_,
            typeKey: CollectionBlockType.input.key,
            title: 'Vintage',
            subtitle: 'Year',
            nowIso: nowIso,
            position: 1,
          ),
          _block(
            id: nextId(),
            collectionId: collectionId,
            parentBlockId: collectionId_,
            typeKey: CollectionBlockType.input.key,
            title: 'Region',
            subtitle: 'Origin region',
            nowIso: nowIso,
            position: 2,
          ),
          _block(
            id: nextId(),
            collectionId: collectionId,
            parentBlockId: collectionId_,
            typeKey: CollectionBlockType.input.key,
            title: 'Grape Variety',
            subtitle: 'e.g. Cabernet, Chardonnay',
            nowIso: nowIso,
            position: 3,
          ),
          _block(
            id: nextId(),
            collectionId: collectionId,
            parentBlockId: collectionId_,
            typeKey: CollectionBlockType.input.key,
            title: 'Price',
            subtitle: 'Purchase price',
            nowIso: nowIso,
            position: 4,
          ),

          // ── Tasting Notes ──
          _block(
            id: tastingId,
            collectionId: collectionId,
            typeKey: CollectionBlockType.section.key,
            title: 'Tasting Notes',
            nowIso: nowIso,
            position: 1,
          ),
          _block(
            id: nextId(),
            collectionId: collectionId,
            parentBlockId: tastingId,
            typeKey: CollectionBlockType.note.key,
            title: 'Tasting Notes',
            description: 'Describe flavors, aromas, and characteristics',
            nowIso: nowIso,
            position: 0,
          ),
          _block(
            id: nextId(),
            collectionId: collectionId,
            parentBlockId: tastingId,
            typeKey: CollectionBlockType.input.key,
            title: 'Rating',
            subtitle: 'Your score out of 10',
            nowIso: nowIso,
            position: 1,
          ),
          _block(
            id: nextId(),
            collectionId: collectionId,
            parentBlockId: tastingId,
            typeKey: CollectionBlockType.input.key,
            title: 'Pairing Suggestions',
            subtitle: 'Food pairings',
            nowIso: nowIso,
            position: 2,
          ),

          // ── Wishlist ──
          _block(
            id: wishlistId,
            collectionId: collectionId,
            typeKey: CollectionBlockType.section.key,
            title: 'Wishlist',
            nowIso: nowIso,
            position: 2,
          ),
          _block(
            id: nextId(),
            collectionId: collectionId,
            parentBlockId: wishlistId,
            typeKey: CollectionBlockType.checklist.key,
            title: 'Wines to Try',
            nowIso: nowIso,
            position: 0,
            checklistItems: [
              CollectionChecklistItemRecordDto(
                id: nextCheckItemId(),
                title: 'Add wines to your wishlist',
                isDone: false,
              ),
            ],
          ),
          _block(
            id: nextId(),
            collectionId: collectionId,
            typeKey: CollectionBlockType.folder.key,
            title: 'Label Photos',
            subtitle: '0 items',
            nowIso: nowIso,
            position: 3,
          ),
          _block(
            id: nextId(),
            collectionId: collectionId,
            typeKey: CollectionBlockType.link.key,
            title: 'Vivino Profile',
            nowIso: nowIso,
            position: 4,
            url: '',
          ),
          _block(
            id: nextId(),
            collectionId: collectionId,
            typeKey: CollectionBlockType.reminder.key,
            title: 'Restock cellar',
            nowIso: nowIso,
            position: 5,
            eventAtIso: now.add(const Duration(days: 30)).toIso8601String(),
          ),
        ];

      case CollectionTemplateType.medicalTracker:
        final medicationsId = nextId();
        final appointmentsId = nextId();
        final recordsId = nextId();
        final insuranceId = nextId();
        return [
          // ── Medications ──
          _block(
            id: medicationsId,
            collectionId: collectionId,
            typeKey: CollectionBlockType.section.key,
            title: 'Medications',
            nowIso: nowIso,
            position: 0,
          ),
          _block(
            id: nextId(),
            collectionId: collectionId,
            parentBlockId: medicationsId,
            typeKey: CollectionBlockType.checklist.key,
            title: 'Current Medications',
            nowIso: nowIso,
            position: 0,
            checklistItems: [
              CollectionChecklistItemRecordDto(
                id: nextCheckItemId(),
                title: 'Add your current medications',
                isDone: false,
              ),
            ],
          ),
          _block(
            id: nextId(),
            collectionId: collectionId,
            parentBlockId: medicationsId,
            typeKey: CollectionBlockType.input.key,
            title: 'Dosage',
            subtitle: 'Dosage information',
            nowIso: nowIso,
            position: 1,
          ),
          _block(
            id: nextId(),
            collectionId: collectionId,
            parentBlockId: medicationsId,
            typeKey: CollectionBlockType.input.key,
            title: 'Prescribing Doctor',
            subtitle: 'Doctor name',
            nowIso: nowIso,
            position: 2,
          ),
          _block(
            id: nextId(),
            collectionId: collectionId,
            parentBlockId: medicationsId,
            typeKey: CollectionBlockType.reminder.key,
            title: 'Refill prescription',
            nowIso: nowIso,
            position: 3,
            eventAtIso: now.add(const Duration(days: 14)).toIso8601String(),
          ),

          // ── Appointments ──
          _block(
            id: appointmentsId,
            collectionId: collectionId,
            typeKey: CollectionBlockType.section.key,
            title: 'Appointments',
            nowIso: nowIso,
            position: 1,
          ),
          _block(
            id: nextId(),
            collectionId: collectionId,
            parentBlockId: appointmentsId,
            typeKey: CollectionBlockType.timeline.key,
            title: 'Next Appointment',
            description: 'Track upcoming medical appointments',
            nowIso: nowIso,
            position: 0,
          ),
          _block(
            id: nextId(),
            collectionId: collectionId,
            parentBlockId: appointmentsId,
            typeKey: CollectionBlockType.input.key,
            title: 'Doctor / Clinic',
            subtitle: 'Provider name',
            nowIso: nowIso,
            position: 1,
          ),
          _block(
            id: nextId(),
            collectionId: collectionId,
            parentBlockId: appointmentsId,
            typeKey: CollectionBlockType.input.key,
            title: 'Phone',
            subtitle: 'Contact phone number',
            nowIso: nowIso,
            position: 2,
          ),

          // ── Records ──
          _block(
            id: recordsId,
            collectionId: collectionId,
            typeKey: CollectionBlockType.section.key,
            title: 'Records',
            nowIso: nowIso,
            position: 2,
          ),
          _block(
            id: nextId(),
            collectionId: collectionId,
            parentBlockId: recordsId,
            typeKey: CollectionBlockType.folder.key,
            title: 'Lab Results',
            subtitle: '0 items',
            nowIso: nowIso,
            position: 0,
          ),
          _block(
            id: nextId(),
            collectionId: collectionId,
            parentBlockId: recordsId,
            typeKey: CollectionBlockType.folder.key,
            title: 'Prescriptions',
            subtitle: '0 items',
            nowIso: nowIso,
            position: 1,
          ),
          _block(
            id: nextId(),
            collectionId: collectionId,
            parentBlockId: recordsId,
            typeKey: CollectionBlockType.note.key,
            title: 'Medical History',
            description: 'Document important medical history information',
            nowIso: nowIso,
            position: 2,
          ),

          // ── Insurance ──
          _block(
            id: insuranceId,
            collectionId: collectionId,
            typeKey: CollectionBlockType.section.key,
            title: 'Insurance',
            nowIso: nowIso,
            position: 3,
          ),
          _block(
            id: nextId(),
            collectionId: collectionId,
            parentBlockId: insuranceId,
            typeKey: CollectionBlockType.input.key,
            title: 'Provider',
            subtitle: 'Insurance provider',
            nowIso: nowIso,
            position: 0,
          ),
          _block(
            id: nextId(),
            collectionId: collectionId,
            parentBlockId: insuranceId,
            typeKey: CollectionBlockType.input.key,
            title: 'Policy Number',
            subtitle: 'Policy number',
            nowIso: nowIso,
            position: 1,
          ),
          _block(
            id: nextId(),
            collectionId: collectionId,
            parentBlockId: insuranceId,
            typeKey: CollectionBlockType.input.key,
            title: 'Group ID',
            subtitle: 'Group ID number',
            nowIso: nowIso,
            position: 2,
          ),
          _block(
            id: nextId(),
            collectionId: collectionId,
            typeKey: CollectionBlockType.link.key,
            title: 'Patient Portal',
            nowIso: nowIso,
            position: 4,
            url: '',
          ),
        ];

      case CollectionTemplateType.emergencyContacts:
        final primaryId = nextId();
        final medicalInfoId = nextId();
        final homeId = nextId();
        return [
          // ── Primary Contacts ──
          _block(
            id: primaryId,
            collectionId: collectionId,
            typeKey: CollectionBlockType.section.key,
            title: 'Primary Contacts',
            nowIso: nowIso,
            position: 0,
          ),
          _block(
            id: nextId(),
            collectionId: collectionId,
            parentBlockId: primaryId,
            typeKey: CollectionBlockType.input.key,
            title: 'Name',
            subtitle: 'Contact name',
            nowIso: nowIso,
            position: 0,
          ),
          _block(
            id: nextId(),
            collectionId: collectionId,
            parentBlockId: primaryId,
            typeKey: CollectionBlockType.input.key,
            title: 'Relation',
            subtitle: 'Relationship',
            nowIso: nowIso,
            position: 1,
          ),
          _block(
            id: nextId(),
            collectionId: collectionId,
            parentBlockId: primaryId,
            typeKey: CollectionBlockType.input.key,
            title: 'Phone',
            subtitle: 'Phone number',
            nowIso: nowIso,
            position: 2,
          ),
          _block(
            id: nextId(),
            collectionId: collectionId,
            parentBlockId: primaryId,
            typeKey: CollectionBlockType.input.key,
            title: 'Email',
            subtitle: 'Email address',
            nowIso: nowIso,
            position: 3,
          ),

          // ── Medical Info ──
          _block(
            id: medicalInfoId,
            collectionId: collectionId,
            typeKey: CollectionBlockType.section.key,
            title: 'Medical Info',
            nowIso: nowIso,
            position: 1,
          ),
          _block(
            id: nextId(),
            collectionId: collectionId,
            parentBlockId: medicalInfoId,
            typeKey: CollectionBlockType.input.key,
            title: 'Blood Type',
            subtitle: 'Blood type',
            nowIso: nowIso,
            position: 0,
          ),
          _block(
            id: nextId(),
            collectionId: collectionId,
            parentBlockId: medicalInfoId,
            typeKey: CollectionBlockType.input.key,
            title: 'Allergies',
            subtitle: 'Known allergies',
            nowIso: nowIso,
            position: 1,
          ),
          _block(
            id: nextId(),
            collectionId: collectionId,
            parentBlockId: medicalInfoId,
            typeKey: CollectionBlockType.note.key,
            title: 'Medical Conditions',
            description: 'Document any medical conditions',
            nowIso: nowIso,
            position: 2,
          ),

          // ── Home ──
          _block(
            id: homeId,
            collectionId: collectionId,
            typeKey: CollectionBlockType.section.key,
            title: 'Home',
            nowIso: nowIso,
            position: 2,
          ),
          _block(
            id: nextId(),
            collectionId: collectionId,
            parentBlockId: homeId,
            typeKey: CollectionBlockType.input.key,
            title: 'Address',
            subtitle: 'Home address',
            nowIso: nowIso,
            position: 0,
          ),
          _block(
            id: nextId(),
            collectionId: collectionId,
            parentBlockId: homeId,
            typeKey: CollectionBlockType.input.key,
            title: 'Landlord/Neighbor Phone',
            subtitle: 'Emergency home contact',
            nowIso: nowIso,
            position: 1,
          ),
          _block(
            id: nextId(),
            collectionId: collectionId,
            typeKey: CollectionBlockType.folder.key,
            title: 'Important Documents',
            subtitle: '0 items',
            nowIso: nowIso,
            position: 3,
          ),
          _block(
            id: nextId(),
            collectionId: collectionId,
            typeKey: CollectionBlockType.link.key,
            title: 'Emergency Services Info',
            nowIso: nowIso,
            position: 4,
            url: '',
          ),
          _block(
            id: nextId(),
            collectionId: collectionId,
            typeKey: CollectionBlockType.reminder.key,
            title: 'Update contacts annually',
            nowIso: nowIso,
            position: 5,
            eventAtIso: now.add(const Duration(days: 365)).toIso8601String(),
          ),
        ];

      case CollectionTemplateType.digitalAccounts:
        final activeId = nextId();
        final subscriptionsId = nextId();
        final archivedId = nextId();
        return [
          // ── Active Accounts ──
          _block(
            id: activeId,
            collectionId: collectionId,
            typeKey: CollectionBlockType.section.key,
            title: 'Active Accounts',
            nowIso: nowIso,
            position: 0,
          ),
          _block(
            id: nextId(),
            collectionId: collectionId,
            parentBlockId: activeId,
            typeKey: CollectionBlockType.input.key,
            title: 'Service Name',
            subtitle: 'Service name',
            nowIso: nowIso,
            position: 0,
          ),
          _block(
            id: nextId(),
            collectionId: collectionId,
            parentBlockId: activeId,
            typeKey: CollectionBlockType.input.key,
            title: 'Email Used',
            subtitle: 'Account email',
            nowIso: nowIso,
            position: 1,
          ),
          _block(
            id: nextId(),
            collectionId: collectionId,
            parentBlockId: activeId,
            typeKey: CollectionBlockType.input.key,
            title: 'Recovery Email',
            subtitle: 'Recovery email address',
            nowIso: nowIso,
            position: 2,
          ),
          _block(
            id: nextId(),
            collectionId: collectionId,
            parentBlockId: activeId,
            typeKey: CollectionBlockType.input.key,
            title: '2FA Method',
            subtitle: 'Two-factor authentication method',
            nowIso: nowIso,
            position: 3,
          ),
          _block(
            id: nextId(),
            collectionId: collectionId,
            parentBlockId: activeId,
            typeKey: CollectionBlockType.input.key,
            title: 'Subscription Status',
            subtitle: 'Active/Premium/Free',
            nowIso: nowIso,
            position: 4,
          ),

          // ── Subscriptions ──
          _block(
            id: subscriptionsId,
            collectionId: collectionId,
            typeKey: CollectionBlockType.section.key,
            title: 'Subscriptions',
            nowIso: nowIso,
            position: 1,
          ),
          _block(
            id: nextId(),
            collectionId: collectionId,
            parentBlockId: subscriptionsId,
            typeKey: CollectionBlockType.checklist.key,
            title: 'Active Subscriptions',
            nowIso: nowIso,
            position: 0,
            checklistItems: [
              CollectionChecklistItemRecordDto(
                id: nextCheckItemId(),
                title: 'List all active subscriptions',
                isDone: false,
              ),
            ],
          ),
          _block(
            id: nextId(),
            collectionId: collectionId,
            parentBlockId: subscriptionsId,
            typeKey: CollectionBlockType.expense.key,
            title: 'Monthly Total',
            description: 'Track total monthly subscription costs',
            nowIso: nowIso,
            position: 1,
          ),

          // ── Archived ──
          _block(
            id: archivedId,
            collectionId: collectionId,
            typeKey: CollectionBlockType.section.key,
            title: 'Archived',
            nowIso: nowIso,
            position: 2,
          ),
          _block(
            id: nextId(),
            collectionId: collectionId,
            parentBlockId: archivedId,
            typeKey: CollectionBlockType.note.key,
            title: 'Closed Accounts',
            description: 'Document closed or deleted accounts',
            nowIso: nowIso,
            position: 0,
          ),
          _block(
            id: nextId(),
            collectionId: collectionId,
            typeKey: CollectionBlockType.folder.key,
            title: 'Account Screenshots',
            subtitle: '0 items',
            nowIso: nowIso,
            position: 3,
          ),
          _block(
            id: nextId(),
            collectionId: collectionId,
            typeKey: CollectionBlockType.reminder.key,
            title: 'Review accounts quarterly',
            nowIso: nowIso,
            position: 4,
            eventAtIso: now.add(const Duration(days: 90)).toIso8601String(),
          ),
          _block(
            id: nextId(),
            collectionId: collectionId,
            typeKey: CollectionBlockType.link.key,
            title: 'Account Settings',
            nowIso: nowIso,
            position: 5,
            url: '',
          ),
        ];

      case CollectionTemplateType.insurancePolicies:
        final activePoliciesId = nextId();
        final contactsId = nextId();
        final claimsId = nextId();
        return [
          // ── Active Policies ──
          _block(
            id: activePoliciesId,
            collectionId: collectionId,
            typeKey: CollectionBlockType.section.key,
            title: 'Active Policies',
            nowIso: nowIso,
            position: 0,
          ),
          _block(
            id: nextId(),
            collectionId: collectionId,
            parentBlockId: activePoliciesId,
            typeKey: CollectionBlockType.input.key,
            title: 'Provider',
            subtitle: 'Insurance provider',
            nowIso: nowIso,
            position: 0,
          ),
          _block(
            id: nextId(),
            collectionId: collectionId,
            parentBlockId: activePoliciesId,
            typeKey: CollectionBlockType.input.key,
            title: 'Policy Number',
            subtitle: 'Policy number',
            nowIso: nowIso,
            position: 1,
          ),
          _block(
            id: nextId(),
            collectionId: collectionId,
            parentBlockId: activePoliciesId,
            typeKey: CollectionBlockType.input.key,
            title: 'Coverage Type',
            subtitle: 'Type of coverage',
            nowIso: nowIso,
            position: 2,
          ),
          _block(
            id: nextId(),
            collectionId: collectionId,
            parentBlockId: activePoliciesId,
            typeKey: CollectionBlockType.input.key,
            title: 'Premium',
            subtitle: 'Premium amount',
            nowIso: nowIso,
            position: 3,
          ),
          _block(
            id: nextId(),
            collectionId: collectionId,
            parentBlockId: activePoliciesId,
            typeKey: CollectionBlockType.input.key,
            title: 'Deductible',
            subtitle: 'Deductible amount',
            nowIso: nowIso,
            position: 4,
          ),

          // ── Contacts ──
          _block(
            id: contactsId,
            collectionId: collectionId,
            typeKey: CollectionBlockType.section.key,
            title: 'Contacts',
            nowIso: nowIso,
            position: 1,
          ),
          _block(
            id: nextId(),
            collectionId: collectionId,
            parentBlockId: contactsId,
            typeKey: CollectionBlockType.input.key,
            title: 'Agent Name',
            subtitle: 'Agent name',
            nowIso: nowIso,
            position: 0,
          ),
          _block(
            id: nextId(),
            collectionId: collectionId,
            parentBlockId: contactsId,
            typeKey: CollectionBlockType.input.key,
            title: 'Agent Phone',
            subtitle: 'Agent phone number',
            nowIso: nowIso,
            position: 1,
          ),
          _block(
            id: nextId(),
            collectionId: collectionId,
            parentBlockId: contactsId,
            typeKey: CollectionBlockType.input.key,
            title: 'Agent Email',
            subtitle: 'Agent email address',
            nowIso: nowIso,
            position: 2,
          ),

          // ── Claims ──
          _block(
            id: claimsId,
            collectionId: collectionId,
            typeKey: CollectionBlockType.section.key,
            title: 'Claims',
            nowIso: nowIso,
            position: 2,
          ),
          _block(
            id: nextId(),
            collectionId: collectionId,
            parentBlockId: claimsId,
            typeKey: CollectionBlockType.checklist.key,
            title: 'Open Claims',
            nowIso: nowIso,
            position: 0,
            checklistItems: [
              CollectionChecklistItemRecordDto(
                id: nextCheckItemId(),
                title: 'Add open claims',
                isDone: false,
              ),
            ],
          ),
          _block(
            id: nextId(),
            collectionId: collectionId,
            parentBlockId: claimsId,
            typeKey: CollectionBlockType.note.key,
            title: 'Claim History',
            description: 'Document past claims and outcomes',
            nowIso: nowIso,
            position: 1,
          ),
          _block(
            id: nextId(),
            collectionId: collectionId,
            parentBlockId: claimsId,
            typeKey: CollectionBlockType.folder.key,
            title: 'Claim Documents',
            subtitle: '0 items',
            nowIso: nowIso,
            position: 2,
          ),
          _block(
            id: nextId(),
            collectionId: collectionId,
            typeKey: CollectionBlockType.timeline.key,
            title: 'Renewal Date',
            description: 'Track policy renewal dates',
            nowIso: nowIso,
            position: 3,
          ),
          _block(
            id: nextId(),
            collectionId: collectionId,
            typeKey: CollectionBlockType.reminder.key,
            title: 'Review coverage annually',
            nowIso: nowIso,
            position: 4,
            eventAtIso: now.add(const Duration(days: 365)).toIso8601String(),
          ),
          _block(
            id: nextId(),
            collectionId: collectionId,
            typeKey: CollectionBlockType.link.key,
            title: 'Insurance Portal',
            nowIso: nowIso,
            position: 5,
            url: '',
          ),
        ];
    }
  }
}
