import 'package:flutter/widgets.dart';
import 'package:pass_doc_manager/domain/collections/entities/collection_block_entity.dart';
import 'package:pass_doc_manager/domain/collections/entities/collection_block_type.dart';
import 'package:pass_doc_manager/features/collections/presentation/pages/collection_add_block_pages.dart';

Widget createCollectionEntryPageForType({
  required CollectionBlockType type,
  required String collectionId,
  String? parentBlockId,
  CollectionBlockEntity? initialBlock,
}) {
  return switch (type) {
    CollectionBlockType.folder => AddFolderBlockPage(
      collectionId: collectionId,
      parentBlockId: parentBlockId,
      initialBlock: initialBlock,
    ),
    CollectionBlockType.section => AddSectionBlockPage(
      collectionId: collectionId,
      parentBlockId: parentBlockId,
      initialBlock: initialBlock,
    ),
    CollectionBlockType.document => AddDocumentBlockPage(
      collectionId: collectionId,
      parentBlockId: parentBlockId,
      initialBlock: initialBlock,
    ),
    CollectionBlockType.note => AddNoteBlockPage(
      collectionId: collectionId,
      parentBlockId: parentBlockId,
      initialBlock: initialBlock,
    ),
    CollectionBlockType.input => AddInputBlockPage(
      collectionId: collectionId,
      parentBlockId: parentBlockId,
      initialBlock: initialBlock,
    ),
    CollectionBlockType.checklist => AddChecklistBlockPage(
      collectionId: collectionId,
      parentBlockId: parentBlockId,
      initialBlock: initialBlock,
    ),
    CollectionBlockType.link => AddLinkBlockPage(
      collectionId: collectionId,
      parentBlockId: parentBlockId,
      initialBlock: initialBlock,
    ),
    CollectionBlockType.image => AddImageBlockPage(
      collectionId: collectionId,
      parentBlockId: parentBlockId,
      initialBlock: initialBlock,
    ),
    CollectionBlockType.expense => AddExpenseBlockPage(
      collectionId: collectionId,
      parentBlockId: parentBlockId,
      initialBlock: initialBlock,
    ),
    CollectionBlockType.timeline => AddTimelineEventBlockPage(
      collectionId: collectionId,
      parentBlockId: parentBlockId,
      initialBlock: initialBlock,
    ),
    CollectionBlockType.location => AddLocationBlockPage(
      collectionId: collectionId,
      parentBlockId: parentBlockId,
      initialBlock: initialBlock,
    ),
    CollectionBlockType.reminder => AddReminderBlockPage(
      collectionId: collectionId,
      parentBlockId: parentBlockId,
      initialBlock: initialBlock,
    ),
    CollectionBlockType.progress => AddProgressBlockPage(
      collectionId: collectionId,
      parentBlockId: parentBlockId,
      initialBlock: initialBlock,
    ),
  };
}
