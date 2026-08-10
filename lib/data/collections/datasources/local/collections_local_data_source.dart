import 'dart:convert';

import 'package:hive/hive.dart';
import 'package:pass_doc_manager/data/collections/dtos/collection_record_dto.dart';
import 'package:pass_doc_manager/data/shared/storage/encrypted_hive_box_factory.dart';
import 'package:pass_doc_manager/core/utils/local_asset_path_resolver.dart';
import 'package:pass_doc_manager/domain/collections/entities/collection_block_metadata_keys.dart';

class CollectionsLocalDataSource {
  CollectionsLocalDataSource._({required Box<dynamic> box}) : _box = box;

  static const _boxName = 'credence_collections_v1';
  static const _stateKey = 'collections_state';

  final Box<dynamic> _box;

  static Future<CollectionsLocalDataSource> create() async {
    final box = await EncryptedHiveBoxFactory.openEncryptedBox(_boxName);
    final dataSource = CollectionsLocalDataSource._(box: box);
    await dataSource._seedIfNeeded();
    await dataSource._migratePathsToPortableFormatIfNeeded();
    await dataSource._migrateCollectionPositionsIfNeeded();
    return dataSource;
  }

  Future<List<CollectionRecordDto>> getCollections() async {
    await LocalAssetPathResolver.getAppSupportPath();
    final raw = _box.get(_stateKey);
    final normalized = _resolveRuntimeState(_normalizeState(raw));
    final List<dynamic> rawList = normalized['items'] as List<dynamic>;
    return rawList
        .whereType<Map>()
        .map(
          (map) => CollectionRecordDto.fromMap(Map<String, dynamic>.from(map)),
        )
        .where((dto) => dto.id.trim().isNotEmpty)
        .toList(growable: false)
      ..sort(_compareCollectionRecords);
  }

  Future<void> saveCollections(List<CollectionRecordDto> collections) async {
    final ordered = collections.toList(growable: false)
      ..sort(_compareCollectionRecords);
    await _box.put(
      _stateKey,
      _toStoredPortableState({
        'items': ordered.map((item) => item.toMap()).toList(growable: false),
      }),
    );
  }

  final Set<String> _generatedCollectionIds = {};

  String nextCollectionId() {
    final existing = _collectionIds()..addAll(_generatedCollectionIds);
    var idx = existing.length + 1;
    var candidate = 'collection_$idx';
    while (existing.contains(candidate)) {
      idx += 1;
      candidate = 'collection_$idx';
    }
    _generatedCollectionIds.add(candidate);
    return candidate;
  }

  final Set<String> _generatedBlockIds = {};

  String nextBlockId() {
    final existing = _blockIds()..addAll(_generatedBlockIds);
    var idx = existing.length + 1;
    var candidate = 'block_$idx';
    while (existing.contains(candidate)) {
      idx += 1;
      candidate = 'block_$idx';
    }
    _generatedBlockIds.add(candidate);
    return candidate;
  }

  Set<String> _collectionIds() {
    final raw = _box.get(_stateKey);
    final normalized = _normalizeState(raw);
    final List<dynamic> rawList = normalized['items'] as List<dynamic>;
    return rawList
        .whereType<Map>()
        .map((map) => '${map['id']}'.trim())
        .where((value) => value.isNotEmpty && value.toLowerCase() != 'null')
        .toSet();
  }

  Set<String> _blockIds() {
    final raw = _box.get(_stateKey);
    final normalized = _normalizeState(raw);
    final List<dynamic> rawCollections = normalized['items'] as List<dynamic>;
    final ids = <String>{};
    for (final rawCollection in rawCollections.whereType<Map>()) {
      final blocksRaw = rawCollection['blocks'];
      if (blocksRaw is! List) {
        continue;
      }
      for (final rawBlock in blocksRaw.whereType<Map>()) {
        final id = '${rawBlock['id']}'.trim();
        if (id.isEmpty || id.toLowerCase() == 'null') {
          continue;
        }
        ids.add(id);
      }
    }
    return ids;
  }

  Map<String, dynamic> _normalizeState(dynamic raw) {
    if (raw is Map<String, dynamic>) {
      final items = raw['items'];
      return {'items': items is List ? items : <dynamic>[]};
    }
    if (raw is Map) {
      final casted = Map<String, dynamic>.from(raw);
      final items = casted['items'];
      return {'items': items is List ? items : <dynamic>[]};
    }
    return {'items': <dynamic>[]};
  }

  Future<void> _migratePathsToPortableFormatIfNeeded() async {
    if (!_box.containsKey(_stateKey)) {
      return;
    }
    final raw = _box.get(_stateKey);
    final normalized = _normalizeState(raw);
    final portable = _toStoredPortableState(normalized);
    if (jsonEncode(normalized) == jsonEncode(portable)) {
      return;
    }
    await _box.put(_stateKey, portable);
  }

  Future<void> _migrateCollectionPositionsIfNeeded() async {
    if (!_box.containsKey(_stateKey)) {
      return;
    }

    final raw = _box.get(_stateKey);
    final normalized = _normalizeState(raw);
    final items = normalized['items'];
    if (items is! List || items.isEmpty) {
      return;
    }

    final rawMaps = items
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList(growable: false);
    if (rawMaps.isEmpty) {
      return;
    }

    final hasMissingPosition = rawMaps.any(
      (item) => !item.containsKey('position'),
    );
    final records = rawMaps
        .map(CollectionRecordDto.fromMap)
        .toList(growable: false);
    final distinctPositions = records.map((item) => item.position).toSet();
    final hasUniquePositions = distinctPositions.length == records.length;

    final ordered = records.toList(growable: false)
      ..sort(
        hasMissingPosition || !hasUniquePositions
            ? (a, b) => b.updatedAtIso.compareTo(a.updatedAtIso)
            : _compareCollectionRecords,
      );

    var needsRewrite = hasMissingPosition || !hasUniquePositions;
    for (var i = 0; i < ordered.length; i++) {
      if (ordered[i].position != i) {
        needsRewrite = true;
        break;
      }
    }
    if (!needsRewrite) {
      return;
    }

    final migrated = [
      for (var i = 0; i < ordered.length; i++) ordered[i].copyWith(position: i),
    ];
    await saveCollections(migrated);
  }

  Map<String, dynamic> _toStoredPortableState(Map<String, dynamic> state) {
    final items = state['items'];
    if (items is! List) {
      return {'items': <dynamic>[]};
    }

    return {
      'items': items
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .map(_toStoredPortableCollection)
          .toList(growable: false),
    };
  }

  Map<String, dynamic> _resolveRuntimeState(Map<String, dynamic> state) {
    final items = state['items'];
    if (items is! List) {
      return {'items': <dynamic>[]};
    }

    return {
      'items': items
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .map(_resolveRuntimeCollection)
          .toList(growable: false),
    };
  }

  Map<String, dynamic> _toStoredPortableCollection(Map<String, dynamic> item) {
    final copy = Map<String, dynamic>.from(item);
    copy['cover_image_url'] = _toStoredPortableValue(copy['cover_image_url']);
    copy['icon_image_path'] = _toStoredPortableValue(copy['icon_image_path']);
    final blocks = copy['blocks'];
    if (blocks is List) {
      copy['blocks'] = blocks
          .whereType<Map>()
          .map((block) => Map<String, dynamic>.from(block))
          .map(_toStoredPortableBlock)
          .toList(growable: false);
    }
    return copy;
  }

  Map<String, dynamic> _resolveRuntimeCollection(Map<String, dynamic> item) {
    final copy = Map<String, dynamic>.from(item);
    copy['cover_image_url'] = _resolveRuntimeValue(copy['cover_image_url']);
    copy['icon_image_path'] = _resolveRuntimeValue(copy['icon_image_path']);
    final blocks = copy['blocks'];
    if (blocks is List) {
      copy['blocks'] = blocks
          .whereType<Map>()
          .map((block) => Map<String, dynamic>.from(block))
          .map(_resolveRuntimeBlock)
          .toList(growable: false);
    }
    return copy;
  }

  Map<String, dynamic> _toStoredPortableBlock(Map<String, dynamic> block) {
    final copy = Map<String, dynamic>.from(block);
    copy['image_url'] = _toStoredPortableValue(copy['image_url']);
    copy['file_path'] = _toStoredPortableValue(copy['file_path']);
    copy['metadata'] = _toStoredPortableMetadata(copy['metadata']);
    return copy;
  }

  Map<String, dynamic> _resolveRuntimeBlock(Map<String, dynamic> block) {
    final copy = Map<String, dynamic>.from(block);
    copy['image_url'] = _resolveRuntimeValue(copy['image_url']);
    copy['file_path'] = _resolveRuntimeValue(copy['file_path']);
    copy['metadata'] = _resolveRuntimeMetadata(copy['metadata']);
    return copy;
  }

  Map<String, dynamic> _toStoredPortableMetadata(dynamic rawMetadata) {
    if (rawMetadata is! Map) {
      return const <String, dynamic>{};
    }
    final metadata = Map<String, dynamic>.from(rawMetadata);
    final iconPath = metadata[CollectionBlockMetadataKeys.iconImagePath];
    final portableIconPath = _toStoredPortableValue(iconPath);
    if (portableIconPath == null) {
      metadata.remove(CollectionBlockMetadataKeys.iconImagePath);
    } else {
      metadata[CollectionBlockMetadataKeys.iconImagePath] = portableIconPath;
    }
    return metadata;
  }

  Map<String, dynamic> _resolveRuntimeMetadata(dynamic rawMetadata) {
    if (rawMetadata is! Map) {
      return const <String, dynamic>{};
    }
    final metadata = Map<String, dynamic>.from(rawMetadata);
    final iconPath = metadata[CollectionBlockMetadataKeys.iconImagePath];
    final resolvedIconPath = _resolveRuntimeValue(iconPath);
    if (resolvedIconPath == null) {
      metadata.remove(CollectionBlockMetadataKeys.iconImagePath);
    } else {
      metadata[CollectionBlockMetadataKeys.iconImagePath] = resolvedIconPath;
    }
    return metadata;
  }

  String? _toStoredPortableValue(dynamic rawValue) {
    final value = '$rawValue'.trim();
    if (value.isEmpty || value.toLowerCase() == 'null') {
      return null;
    }
    final portable = LocalAssetPathResolver.toStoredPortablePath(value);
    return portable.isEmpty ? null : portable;
  }

  String? _resolveRuntimeValue(dynamic rawValue) {
    final value = '$rawValue'.trim();
    if (value.isEmpty || value.toLowerCase() == 'null') {
      return null;
    }
    final resolved = LocalAssetPathResolver.resolveRuntimePathSync(value);
    return resolved.isEmpty ? null : resolved;
  }

  static int _compareCollectionRecords(
    CollectionRecordDto a,
    CollectionRecordDto b,
  ) {
    final positionCompare = a.position.compareTo(b.position);
    if (positionCompare != 0) {
      return positionCompare;
    }
    return b.updatedAtIso.compareTo(a.updatedAtIso);
  }

  Future<void> _seedIfNeeded() async {
    return;
    // ignore: dead_code
    if (_box.containsKey(_stateKey)) {
      final items = (await getCollections());
      if (items.isNotEmpty) {
        return;
      }
    }

    final now = DateTime.now();
    final items = <CollectionRecordDto>[
      CollectionRecordDto(
        id: 'collection_japan_trip',
        name: 'Japan Trip',
        subtitle: 'Oct 12 - Oct 28, 2026',
        iconKey: 'map',
        accentColorHex: '#1152D4',
        startDateIso: now.add(const Duration(days: 12)).toIso8601String(),
        endDateIso: now.add(const Duration(days: 28)).toIso8601String(),
        coverImageUrl:
            'https://images.unsplash.com/photo-1536098561742-ca998e48cbcc?auto=format&fit=crop&w=1400&q=80',
        updatedAtIso: now.subtract(const Duration(hours: 2)).toIso8601String(),
        blocks: [
          CollectionBlockRecordDto(
            id: 'block_folder_itinerary',
            collectionId: 'collection_japan_trip',
            parentBlockId: null,
            typeKey: 'folder',
            title: 'Itinerary',
            subtitle: '8 items • Updated 2h ago',
            description: 'Daily timeline and routing',
            createdAtIso: now
                .subtract(const Duration(days: 4))
                .toIso8601String(),
            updatedAtIso: now
                .subtract(const Duration(hours: 2))
                .toIso8601String(),
            imageUrl: null,
            fileType: null,
            fileSizeLabel: null,
            url: null,
            domainLabel: null,
            currencyCode: null,
            amount: null,
            eventAtIso: null,
            expiryDateIso: null,
            latitude: null,
            longitude: null,
            locationLabel: null,
            isCompleted: false,
            statusLabel: null,
            tags: const ['travel'],
            metadata: const {'updated': '2h ago'},
            checklistItems: const [],
          ),
          CollectionBlockRecordDto(
            id: 'block_folder_bookings',
            collectionId: 'collection_japan_trip',
            parentBlockId: null,
            typeKey: 'folder',
            title: 'Bookings & Tickets',
            subtitle: '14 items • Updated 1d ago',
            description: 'Flights, rail passes and stays',
            createdAtIso: now
                .subtract(const Duration(days: 4))
                .toIso8601String(),
            updatedAtIso: now
                .subtract(const Duration(days: 1))
                .toIso8601String(),
            imageUrl: null,
            fileType: null,
            fileSizeLabel: null,
            url: null,
            domainLabel: null,
            currencyCode: null,
            amount: null,
            eventAtIso: null,
            expiryDateIso: null,
            latitude: null,
            longitude: null,
            locationLabel: null,
            isCompleted: false,
            statusLabel: null,
            tags: const ['travel'],
            metadata: const {'updated': '1d ago'},
            checklistItems: const [],
          ),
          CollectionBlockRecordDto(
            id: 'block_folder_budget',
            collectionId: 'collection_japan_trip',
            parentBlockId: null,
            typeKey: 'folder',
            title: 'Budget & Expenses',
            subtitle: '3 items • Updated 5m ago',
            description: 'Trip budget and expenses',
            createdAtIso: now
                .subtract(const Duration(days: 4))
                .toIso8601String(),
            updatedAtIso: now
                .subtract(const Duration(minutes: 5))
                .toIso8601String(),
            imageUrl: null,
            fileType: null,
            fileSizeLabel: null,
            url: null,
            domainLabel: null,
            currencyCode: null,
            amount: null,
            eventAtIso: null,
            expiryDateIso: null,
            latitude: null,
            longitude: null,
            locationLabel: null,
            isCompleted: false,
            statusLabel: null,
            tags: const ['budget'],
            metadata: const {'updated': '5m ago'},
            checklistItems: const [],
          ),
          CollectionBlockRecordDto(
            id: 'block_doc_kyoto',
            collectionId: 'collection_japan_trip',
            parentBlockId: 'block_folder_itinerary',
            typeKey: 'document',
            title: 'Kyoto Temple Guide',
            subtitle: 'Doc • 12kb',
            description: 'Temple visiting order and train recommendations.',
            createdAtIso: now
                .subtract(const Duration(days: 2))
                .toIso8601String(),
            updatedAtIso: now
                .subtract(const Duration(days: 2))
                .toIso8601String(),
            imageUrl:
                'https://images.unsplash.com/photo-1493976040374-85c8e12f0c0e?auto=format&fit=crop&w=1200&q=80',
            fileType: 'PDF',
            fileSizeLabel: '12 KB',
            url: null,
            domainLabel: null,
            currencyCode: null,
            amount: null,
            eventAtIso: null,
            expiryDateIso: null,
            latitude: null,
            longitude: null,
            locationLabel: null,
            isCompleted: false,
            statusLabel: 'Preview available',
            tags: const ['travel', 'guide'],
            metadata: const {'stored_in': 'Itinerary'},
            checklistItems: const [],
          ),
          CollectionBlockRecordDto(
            id: 'block_note_shinjuku_food',
            collectionId: 'collection_japan_trip',
            parentBlockId: 'block_folder_itinerary',
            typeKey: 'note',
            title: 'Shinjuku Food List',
            subtitle: 'Note • 482 words',
            description: 'Sushi, ramen and coffee spots near the hotel.',
            createdAtIso: now
                .subtract(const Duration(days: 1))
                .toIso8601String(),
            updatedAtIso: now
                .subtract(const Duration(days: 1))
                .toIso8601String(),
            imageUrl: null,
            fileType: null,
            fileSizeLabel: null,
            url: null,
            domainLabel: null,
            currencyCode: null,
            amount: null,
            eventAtIso: null,
            expiryDateIso: null,
            latitude: null,
            longitude: null,
            locationLabel: null,
            isCompleted: false,
            statusLabel: 'Reference',
            tags: const ['food', 'tokyo'],
            metadata: const {'collection': 'Japan Trip'},
            checklistItems: const [],
          ),
          CollectionBlockRecordDto(
            id: 'block_timeline_arrival',
            collectionId: 'collection_japan_trip',
            parentBlockId: 'block_folder_itinerary',
            typeKey: 'timeline',
            title: 'Narita Airport Arrival',
            subtitle: 'Tomorrow • 09:00 AM',
            description:
                'Terminal 2, Flight JL006. Pick up JR Pass at counter.',
            createdAtIso: now
                .subtract(const Duration(days: 3))
                .toIso8601String(),
            updatedAtIso: now
                .subtract(const Duration(hours: 8))
                .toIso8601String(),
            imageUrl: null,
            fileType: null,
            fileSizeLabel: null,
            url: null,
            domainLabel: null,
            currencyCode: null,
            amount: null,
            eventAtIso: now
                .add(const Duration(days: 1, hours: 9))
                .toIso8601String(),
            expiryDateIso: null,
            latitude: 35.77199,
            longitude: 140.39285,
            locationLabel: 'Narita Airport Terminal 2',
            isCompleted: false,
            statusLabel: 'Critical',
            tags: const ['travel'],
            metadata: const {'participants': '2', 'documents': '2'},
            checklistItems: const [],
          ),
          CollectionBlockRecordDto(
            id: 'block_timeline_checkin',
            collectionId: 'collection_japan_trip',
            parentBlockId: 'block_folder_itinerary',
            typeKey: 'timeline',
            title: 'Check-in: Park Hyatt Tokyo',
            subtitle: 'Fri • 03:00 PM',
            description: 'Reservation #A9K23B. Shinjuku area.',
            createdAtIso: now
                .subtract(const Duration(days: 2))
                .toIso8601String(),
            updatedAtIso: now
                .subtract(const Duration(days: 1))
                .toIso8601String(),
            imageUrl: null,
            fileType: null,
            fileSizeLabel: null,
            url: null,
            domainLabel: null,
            currencyCode: null,
            amount: null,
            eventAtIso: now
                .add(const Duration(days: 2, hours: 15))
                .toIso8601String(),
            expiryDateIso: null,
            latitude: 35.6853,
            longitude: 139.6947,
            locationLabel: 'Shinjuku',
            isCompleted: false,
            statusLabel: 'Planned',
            tags: const ['stay'],
            metadata: const {'participants': '2', 'documents': '1'},
            checklistItems: const [],
          ),
          CollectionBlockRecordDto(
            id: 'block_expense_filter',
            collectionId: 'collection_japan_trip',
            parentBlockId: 'block_folder_budget',
            typeKey: 'expense',
            title: 'Lens Filter',
            subtitle: 'Equipment',
            description: 'Replacement UV filter purchased before trip.',
            createdAtIso: now
                .subtract(const Duration(hours: 5))
                .toIso8601String(),
            updatedAtIso: now
                .subtract(const Duration(hours: 5))
                .toIso8601String(),
            imageUrl: null,
            fileType: 'JPG',
            fileSizeLabel: '1.3 MB',
            url: null,
            domainLabel: null,
            currencyCode: 'USD',
            amount: 45,
            eventAtIso: now
                .subtract(const Duration(hours: 5))
                .toIso8601String(),
            expiryDateIso: null,
            latitude: 37.7749,
            longitude: -122.4194,
            locationLabel: 'Camera Pro Shop, San Francisco',
            isCompleted: true,
            statusLabel: 'Completed',
            tags: const ['equipment'],
            metadata: const {'paid_with': 'Visa •••• 4242'},
            checklistItems: const [],
          ),
          CollectionBlockRecordDto(
            id: 'block_location_riverside',
            collectionId: 'collection_japan_trip',
            parentBlockId: 'block_folder_itinerary',
            typeKey: 'location',
            title: 'Riverside Park',
            subtitle: '123 West Riverfront St, Tokyo',
            description: 'Golden hour photo location.',
            createdAtIso: now
                .subtract(const Duration(days: 1))
                .toIso8601String(),
            updatedAtIso: now
                .subtract(const Duration(days: 1))
                .toIso8601String(),
            imageUrl:
                'https://images.unsplash.com/photo-1549692520-acc6669e2f0c?auto=format&fit=crop&w=1200&q=80',
            fileType: null,
            fileSizeLabel: null,
            url: 'https://maps.google.com/?q=Riverside+Park+Tokyo',
            domainLabel: 'maps.google.com',
            currencyCode: null,
            amount: null,
            eventAtIso: null,
            expiryDateIso: null,
            latitude: 35.706,
            longitude: 139.752,
            locationLabel: 'Tokyo',
            isCompleted: false,
            statusLabel: 'Active',
            tags: const ['location'],
            metadata: const {
              'category': 'Park & Recreation',
              'opening_hours': '06:00 - 22:00',
            },
            checklistItems: const [],
          ),
          CollectionBlockRecordDto(
            id: 'block_link_tutorial',
            collectionId: 'collection_japan_trip',
            parentBlockId: 'block_folder_itinerary',
            typeKey: 'link',
            title: 'Lighting Tutorial',
            subtitle: 'youtube.com',
            description: 'Night photography light setup tutorial.',
            createdAtIso: now
                .subtract(const Duration(days: 8))
                .toIso8601String(),
            updatedAtIso: now
                .subtract(const Duration(days: 2))
                .toIso8601String(),
            imageUrl:
                'https://images.unsplash.com/photo-1500530855697-b586d89ba3ee?auto=format&fit=crop&w=1200&q=80',
            fileType: null,
            fileSizeLabel: null,
            url: 'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
            domainLabel: 'youtube.com',
            currencyCode: null,
            amount: null,
            eventAtIso: null,
            expiryDateIso: null,
            latitude: null,
            longitude: null,
            locationLabel: null,
            isCompleted: false,
            statusLabel: null,
            tags: const ['lighting', 'video', 'tutorial'],
            metadata: const {'added_by': 'Alex Rivera'},
            checklistItems: const [],
          ),
          CollectionBlockRecordDto(
            id: 'block_input_serial',
            collectionId: 'collection_japan_trip',
            parentBlockId: 'block_folder_bookings',
            typeKey: 'input',
            title: 'Camera Serial',
            subtitle: 'SN-8423921',
            description: 'Camera hardware serial number',
            createdAtIso: now
                .subtract(const Duration(days: 4))
                .toIso8601String(),
            updatedAtIso: now
                .subtract(const Duration(days: 3))
                .toIso8601String(),
            imageUrl: null,
            fileType: null,
            fileSizeLabel: null,
            url: null,
            domainLabel: null,
            currencyCode: null,
            amount: null,
            eventAtIso: null,
            expiryDateIso: null,
            latitude: null,
            longitude: null,
            locationLabel: null,
            isCompleted: true,
            statusLabel: 'Active',
            tags: const ['equipment'],
            metadata: const {
              'label': 'Camera Serial',
              'type': 'Input Block',
              'last_updated': 'Oct 24, 2023',
              'hardware_model': 'X-Pro Vision 2',
            },
            checklistItems: const [],
          ),
          CollectionBlockRecordDto(
            id: 'block_checklist_studio',
            collectionId: 'collection_japan_trip',
            parentBlockId: 'block_folder_bookings',
            typeKey: 'checklist',
            title: 'Studio Setup',
            subtitle: '3 of 7 tasks',
            description: 'Before-departure equipment checklist.',
            createdAtIso: now
                .subtract(const Duration(days: 9))
                .toIso8601String(),
            updatedAtIso: now
                .subtract(const Duration(days: 1))
                .toIso8601String(),
            imageUrl: null,
            fileType: null,
            fileSizeLabel: null,
            url: null,
            domainLabel: null,
            currencyCode: null,
            amount: null,
            eventAtIso: null,
            expiryDateIso: null,
            latitude: null,
            longitude: null,
            locationLabel: null,
            isCompleted: false,
            statusLabel: null,
            tags: const ['project'],
            metadata: const {
              'assignee': 'John Doe',
              'due_date': 'Oct 24, 2023',
            },
            checklistItems: const [
              CollectionChecklistItemRecordDto(
                id: 'checklist_1',
                title: 'Order acoustic foam',
                isDone: true,
              ),
              CollectionChecklistItemRecordDto(
                id: 'checklist_2',
                title: 'Set up desk',
                isDone: true,
              ),
              CollectionChecklistItemRecordDto(
                id: 'checklist_3',
                title: 'Mount monitors',
                isDone: true,
              ),
              CollectionChecklistItemRecordDto(
                id: 'checklist_4',
                title: 'Connect audio interface',
                isDone: false,
              ),
              CollectionChecklistItemRecordDto(
                id: 'checklist_5',
                title: 'Calibrate microphones',
                isDone: false,
              ),
              CollectionChecklistItemRecordDto(
                id: 'checklist_6',
                title: 'Cable management',
                isDone: false,
              ),
              CollectionChecklistItemRecordDto(
                id: 'checklist_7',
                title: 'Test recording levels',
                isDone: false,
              ),
            ],
          ),
          CollectionBlockRecordDto(
            id: 'block_image_sunset',
            collectionId: 'collection_japan_trip',
            parentBlockId: 'block_folder_itinerary',
            typeKey: 'image',
            title: 'Sunset Shot',
            subtitle: 'IMG_2941.JPG',
            description: 'Reference framing and composition sample.',
            createdAtIso: now
                .subtract(const Duration(days: 5))
                .toIso8601String(),
            updatedAtIso: now
                .subtract(const Duration(days: 5))
                .toIso8601String(),
            imageUrl:
                'https://images.unsplash.com/photo-1470770841072-f978cf4d019e?auto=format&fit=crop&w=1400&q=80',
            fileType: 'JPG',
            fileSizeLabel: '4.2 MB',
            url: null,
            domainLabel: null,
            currencyCode: null,
            amount: null,
            eventAtIso: null,
            expiryDateIso: null,
            latitude: 36.2704,
            longitude: -121.8081,
            locationLabel: 'Big Sur, California',
            isCompleted: false,
            statusLabel: null,
            tags: const ['photo'],
            metadata: const {
              'resolution': '4032 × 3024',
              'device': 'iPhone 14 Pro',
            },
            checklistItems: const [],
          ),
        ],
      ),
      CollectionRecordDto(
        id: 'collection_visa_application',
        name: 'Visa Application',
        subtitle: '18 items • Updated yesterday',
        iconKey: 'description',
        accentColorHex: '#2563EB',
        startDateIso: null,
        endDateIso: null,
        coverImageUrl: null,
        updatedAtIso: now.subtract(const Duration(days: 1)).toIso8601String(),
        blocks: const [],
      ),
      CollectionRecordDto(
        id: 'collection_expense_receipts',
        name: 'Expense Receipts',
        subtitle: '31 items • Updated 3h ago',
        iconKey: 'payments',
        accentColorHex: '#10A26C',
        startDateIso: null,
        endDateIso: null,
        coverImageUrl: null,
        updatedAtIso: now.subtract(const Duration(hours: 3)).toIso8601String(),
        blocks: const [],
      ),
      CollectionRecordDto(
        id: 'collection_dream_home_ideas',
        name: 'Dream Home Ideas',
        subtitle: '26 items • Updated 5d ago',
        iconKey: 'home_work',
        accentColorHex: '#F59E0B',
        startDateIso: null,
        endDateIso: null,
        coverImageUrl: null,
        updatedAtIso: now.subtract(const Duration(days: 5)).toIso8601String(),
        blocks: const [],
      ),
      CollectionRecordDto(
        id: 'collection_project_phoenix',
        name: 'Project Phoenix',
        subtitle: '42 items • Updated 1h ago',
        iconKey: 'workspaces',
        accentColorHex: '#8B5CF6',
        startDateIso: null,
        endDateIso: null,
        coverImageUrl: null,
        updatedAtIso: now.subtract(const Duration(hours: 1)).toIso8601String(),
        blocks: const [],
      ),
    ];

    await saveCollections(items);
  }
}
