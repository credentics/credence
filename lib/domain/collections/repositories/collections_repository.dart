import 'package:pass_doc_manager/domain/collections/entities/collection_block_entity.dart';
import 'package:pass_doc_manager/domain/collections/entities/collection_entity.dart';
import 'package:pass_doc_manager/domain/collections/entities/collection_template_type.dart';

abstract class CollectionsRepository {
  Future<List<CollectionEntity>> getCollections();

  Future<CollectionEntity> getCollectionById({required String collectionId});

  Future<CollectionEntity> createCollection({
    required String name,
    required String iconKey,
    String? iconEmoji,
    String? iconImagePath,
    required String accentColorHex,
    required CollectionTemplateType template,
  });

  Future<void> saveCollection(CollectionEntity collection);

  Future<void> reorderCollections({required List<String> orderedCollectionIds});

  Future<void> saveBlock({
    required String collectionId,
    required CollectionBlockEntity block,
  });

  Future<void> deleteBlock({
    required String collectionId,
    required String blockId,
  });

  Future<void> scheduleBlockReminder({
    required String blockId,
    required String title,
    String? body,
    required DateTime scheduledAt,
    String? repeatInterval,
  });

  Future<void> cancelBlockReminder({required String blockId});

  Future<void> deleteCollection({required String collectionId});
}
