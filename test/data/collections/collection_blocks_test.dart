import 'package:flutter_test/flutter_test.dart';
import 'package:pass_doc_manager/data/collections/dtos/collection_record_dto.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CollectionBlockRecordDto serialization', () {
    test('serializes to map and back', () {
      const block = CollectionBlockRecordDto(
        id: 'block_001',
        collectionId: 'col_001',
        parentBlockId: null,
        typeKey: 'note',
        title: 'My Note',
        subtitle: 'A subtitle',
        description: 'Some description',
        createdAtIso: '2026-01-01T10:00:00Z',
        updatedAtIso: '2026-01-02T10:00:00Z',
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
        tags: ['tag1', 'tag2'],
        metadata: {'key': 'value'},
        checklistItems: [],
        position: 0,
      );

      final map = block.toMap();
      final restored = CollectionBlockRecordDto.fromMap(map);

      expect(restored.id, block.id);
      expect(restored.collectionId, block.collectionId);
      expect(restored.typeKey, block.typeKey);
      expect(restored.title, block.title);
      expect(restored.subtitle, block.subtitle);
      expect(restored.description, block.description);
      expect(restored.tags, block.tags);
      expect(restored.metadata, block.metadata);
      expect(restored.position, block.position);
    });

    test('parentBlockId null means root-level block', () {
      const block = CollectionBlockRecordDto(
        id: 'block_root',
        collectionId: 'col_001',
        parentBlockId: null,
        typeKey: 'section',
        title: 'Root',
        subtitle: '',
        description: '',
        createdAtIso: '2026-01-01T10:00:00Z',
        updatedAtIso: '2026-01-01T10:00:00Z',
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
        tags: [],
        metadata: {},
        checklistItems: [],
      );

      final map = block.toMap();
      expect(map['parent_block_id'], isNull);

      final restored = CollectionBlockRecordDto.fromMap(map);
      expect(restored.parentBlockId, isNull);
    });

    test('parentBlockId set links block to parent', () {
      const block = CollectionBlockRecordDto(
        id: 'block_child',
        collectionId: 'col_001',
        parentBlockId: 'block_root',
        typeKey: 'note',
        title: 'Child',
        subtitle: '',
        description: '',
        createdAtIso: '2026-01-01T10:00:00Z',
        updatedAtIso: '2026-01-01T10:00:00Z',
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
        tags: [],
        metadata: {},
        checklistItems: [],
      );

      final map = block.toMap();
      expect(map['parent_block_id'], 'block_root');

      final restored = CollectionBlockRecordDto.fromMap(map);
      expect(restored.parentBlockId, 'block_root');
    });

    test('blocks sorted by position', () {
      final blocks = [
        _makeBlock(id: 'b3', position: 3),
        _makeBlock(id: 'b1', position: 1),
        _makeBlock(id: 'b2', position: 2),
      ];

      blocks.sort((a, b) => a.position.compareTo(b.position));

      expect(blocks[0].id, 'b1');
      expect(blocks[1].id, 'b2');
      expect(blocks[2].id, 'b3');
    });

    test('block with checklist items serializes correctly', () {
      const block = CollectionBlockRecordDto(
        id: 'block_checklist',
        collectionId: 'col_001',
        parentBlockId: null,
        typeKey: 'checklist',
        title: 'Shopping List',
        subtitle: '',
        description: '',
        createdAtIso: '2026-01-01T10:00:00Z',
        updatedAtIso: '2026-01-01T10:00:00Z',
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
        tags: [],
        metadata: {},
        checklistItems: [
          CollectionChecklistItemRecordDto(
            id: 'item_1',
            title: 'Milk',
            isDone: true,
          ),
          CollectionChecklistItemRecordDto(
            id: 'item_2',
            title: 'Bread',
            isDone: false,
          ),
        ],
      );

      final map = block.toMap();
      final restored = CollectionBlockRecordDto.fromMap(map);

      expect(restored.checklistItems.length, 2);
      expect(restored.checklistItems[0].id, 'item_1');
      expect(restored.checklistItems[0].title, 'Milk');
      expect(restored.checklistItems[0].isDone, isTrue);
      expect(restored.checklistItems[1].id, 'item_2');
      expect(restored.checklistItems[1].isDone, isFalse);
    });

    test('block types parse from key strings', () {
      for (final typeKey in ['note', 'checklist', 'file', 'link', 'expense']) {
        final block = _makeBlock(id: 'block_$typeKey', typeKey: typeKey);
        final map = block.toMap();
        final restored = CollectionBlockRecordDto.fromMap(map);
        expect(restored.typeKey, typeKey);
      }
    });
  });

  group('CollectionRecordDto serialization', () {
    test('toMap and fromMap round-trip', () {
      const collection = CollectionRecordDto(
        id: 'col_001',
        name: 'Travel',
        subtitle: 'Trip to Paris',
        iconKey: 'airplane',
        accentColorHex: '#FF5733',
        startDateIso: '2026-06-01T00:00:00Z',
        endDateIso: '2026-06-15T00:00:00Z',
        coverImageUrl: 'https://example.com/paris.jpg',
        updatedAtIso: '2026-01-15T10:00:00Z',
        blocks: [
          CollectionBlockRecordDto(
            id: 'block_001',
            collectionId: 'col_001',
            parentBlockId: null,
            typeKey: 'note',
            title: 'Packing List',
            subtitle: '',
            description: 'Things to pack',
            createdAtIso: '2026-01-10T10:00:00Z',
            updatedAtIso: '2026-01-10T10:00:00Z',
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
            tags: ['travel'],
            metadata: {},
            checklistItems: [],
          ),
        ],
      );

      final map = collection.toMap();
      final restored = CollectionRecordDto.fromMap(map);

      expect(restored.id, collection.id);
      expect(restored.name, collection.name);
      expect(restored.subtitle, collection.subtitle);
      expect(restored.iconKey, collection.iconKey);
      expect(restored.accentColorHex, collection.accentColorHex);
      expect(restored.startDateIso, collection.startDateIso);
      expect(restored.endDateIso, collection.endDateIso);
      expect(restored.coverImageUrl, collection.coverImageUrl);
      expect(restored.updatedAtIso, collection.updatedAtIso);
      expect(restored.blocks.length, 1);
      expect(restored.blocks.first.id, 'block_001');
      expect(restored.blocks.first.title, 'Packing List');
      expect(restored.blocks.first.tags, ['travel']);
    });
  });
}

CollectionBlockRecordDto _makeBlock({
  required String id,
  int position = 0,
  String typeKey = 'note',
}) {
  return CollectionBlockRecordDto(
    id: id,
    collectionId: 'col_001',
    parentBlockId: null,
    typeKey: typeKey,
    title: 'Block $id',
    subtitle: '',
    description: '',
    createdAtIso: '2026-01-01T10:00:00Z',
    updatedAtIso: '2026-01-01T10:00:00Z',
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
    tags: [],
    metadata: {},
    checklistItems: [],
    position: position,
  );
}
