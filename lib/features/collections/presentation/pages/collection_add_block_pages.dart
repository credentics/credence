import 'package:flutter/material.dart';
import 'package:pass_doc_manager/domain/collections/entities/collection_block_entity.dart';
import 'package:pass_doc_manager/domain/collections/entities/collection_block_type.dart';
import 'package:pass_doc_manager/features/collections/presentation/pages/collection_block_entry_page.dart';

class AddNoteBlockPage extends StatelessWidget {
  const AddNoteBlockPage({
    super.key,
    required this.collectionId,
    this.parentBlockId,
    this.initialBlock,
  });

  final String collectionId;
  final String? parentBlockId;
  final CollectionBlockEntity? initialBlock;

  @override
  Widget build(BuildContext context) {
    return CollectionBlockEntryPage(
      collectionId: collectionId,
      parentBlockId: parentBlockId,
      type: CollectionBlockType.note,
      initialBlock: initialBlock,
    );
  }
}

class AddSectionBlockPage extends StatelessWidget {
  const AddSectionBlockPage({
    super.key,
    required this.collectionId,
    this.parentBlockId,
    this.initialBlock,
  });

  final String collectionId;
  final String? parentBlockId;
  final CollectionBlockEntity? initialBlock;

  @override
  Widget build(BuildContext context) {
    return CollectionBlockEntryPage(
      collectionId: collectionId,
      parentBlockId: parentBlockId,
      type: CollectionBlockType.section,
      initialBlock: initialBlock,
    );
  }
}

class AddDocumentBlockPage extends StatelessWidget {
  const AddDocumentBlockPage({
    super.key,
    required this.collectionId,
    this.parentBlockId,
    this.initialBlock,
  });

  final String collectionId;
  final String? parentBlockId;
  final CollectionBlockEntity? initialBlock;

  @override
  Widget build(BuildContext context) {
    return CollectionBlockEntryPage(
      collectionId: collectionId,
      parentBlockId: parentBlockId,
      type: CollectionBlockType.document,
      initialBlock: initialBlock,
    );
  }
}

class AddImageBlockPage extends StatelessWidget {
  const AddImageBlockPage({
    super.key,
    required this.collectionId,
    this.parentBlockId,
    this.initialBlock,
  });

  final String collectionId;
  final String? parentBlockId;
  final CollectionBlockEntity? initialBlock;

  @override
  Widget build(BuildContext context) {
    return CollectionBlockEntryPage(
      collectionId: collectionId,
      parentBlockId: parentBlockId,
      type: CollectionBlockType.image,
      initialBlock: initialBlock,
    );
  }
}

class AddExpenseBlockPage extends StatelessWidget {
  const AddExpenseBlockPage({
    super.key,
    required this.collectionId,
    this.parentBlockId,
    this.initialBlock,
  });

  final String collectionId;
  final String? parentBlockId;
  final CollectionBlockEntity? initialBlock;

  @override
  Widget build(BuildContext context) {
    return CollectionBlockEntryPage(
      collectionId: collectionId,
      parentBlockId: parentBlockId,
      type: CollectionBlockType.expense,
      initialBlock: initialBlock,
    );
  }
}

class AddTimelineEventBlockPage extends StatelessWidget {
  const AddTimelineEventBlockPage({
    super.key,
    required this.collectionId,
    this.parentBlockId,
    this.initialBlock,
  });

  final String collectionId;
  final String? parentBlockId;
  final CollectionBlockEntity? initialBlock;

  @override
  Widget build(BuildContext context) {
    return CollectionBlockEntryPage(
      collectionId: collectionId,
      parentBlockId: parentBlockId,
      type: CollectionBlockType.timeline,
      initialBlock: initialBlock,
    );
  }
}

class AddLocationBlockPage extends StatelessWidget {
  const AddLocationBlockPage({
    super.key,
    required this.collectionId,
    this.parentBlockId,
    this.initialBlock,
  });

  final String collectionId;
  final String? parentBlockId;
  final CollectionBlockEntity? initialBlock;

  @override
  Widget build(BuildContext context) {
    return CollectionBlockEntryPage(
      collectionId: collectionId,
      parentBlockId: parentBlockId,
      type: CollectionBlockType.location,
      initialBlock: initialBlock,
    );
  }
}

class AddChecklistBlockPage extends StatelessWidget {
  const AddChecklistBlockPage({
    super.key,
    required this.collectionId,
    this.parentBlockId,
    this.initialBlock,
  });

  final String collectionId;
  final String? parentBlockId;
  final CollectionBlockEntity? initialBlock;

  @override
  Widget build(BuildContext context) {
    return CollectionBlockEntryPage(
      collectionId: collectionId,
      parentBlockId: parentBlockId,
      type: CollectionBlockType.checklist,
      initialBlock: initialBlock,
    );
  }
}

class AddLinkBlockPage extends StatelessWidget {
  const AddLinkBlockPage({
    super.key,
    required this.collectionId,
    this.parentBlockId,
    this.initialBlock,
  });

  final String collectionId;
  final String? parentBlockId;
  final CollectionBlockEntity? initialBlock;

  @override
  Widget build(BuildContext context) {
    return CollectionBlockEntryPage(
      collectionId: collectionId,
      parentBlockId: parentBlockId,
      type: CollectionBlockType.link,
      initialBlock: initialBlock,
    );
  }
}

class AddInputBlockPage extends StatelessWidget {
  const AddInputBlockPage({
    super.key,
    required this.collectionId,
    this.parentBlockId,
    this.initialBlock,
  });

  final String collectionId;
  final String? parentBlockId;
  final CollectionBlockEntity? initialBlock;

  @override
  Widget build(BuildContext context) {
    return CollectionBlockEntryPage(
      collectionId: collectionId,
      parentBlockId: parentBlockId,
      type: CollectionBlockType.input,
      initialBlock: initialBlock,
    );
  }
}

class AddReminderBlockPage extends StatelessWidget {
  const AddReminderBlockPage({
    super.key,
    required this.collectionId,
    this.parentBlockId,
    this.initialBlock,
  });

  final String collectionId;
  final String? parentBlockId;
  final CollectionBlockEntity? initialBlock;

  @override
  Widget build(BuildContext context) {
    return CollectionBlockEntryPage(
      collectionId: collectionId,
      parentBlockId: parentBlockId,
      type: CollectionBlockType.reminder,
      initialBlock: initialBlock,
    );
  }
}

class AddFolderBlockPage extends StatelessWidget {
  const AddFolderBlockPage({
    super.key,
    required this.collectionId,
    this.parentBlockId,
    this.initialBlock,
  });

  final String collectionId;
  final String? parentBlockId;
  final CollectionBlockEntity? initialBlock;

  @override
  Widget build(BuildContext context) {
    return CollectionBlockEntryPage(
      collectionId: collectionId,
      parentBlockId: parentBlockId,
      type: CollectionBlockType.folder,
      initialBlock: initialBlock,
    );
  }
}

class AddProgressBlockPage extends StatelessWidget {
  const AddProgressBlockPage({
    super.key,
    required this.collectionId,
    this.parentBlockId,
    this.initialBlock,
  });

  final String collectionId;
  final String? parentBlockId;
  final CollectionBlockEntity? initialBlock;

  @override
  Widget build(BuildContext context) {
    return CollectionBlockEntryPage(
      collectionId: collectionId,
      parentBlockId: parentBlockId,
      type: CollectionBlockType.progress,
      initialBlock: initialBlock,
    );
  }
}
