import 'package:flutter/material.dart';
import 'package:pass_doc_manager/domain/collections/entities/collection_block_entity.dart';
import 'package:pass_doc_manager/features/collections/presentation/pages/collection_block_detail_page.dart';

class DocumentDetailsPage extends StatelessWidget {
  const DocumentDetailsPage({
    super.key,
    required this.collectionId,
    required this.block,
  });

  final String collectionId;
  final CollectionBlockEntity block;

  @override
  Widget build(BuildContext context) {
    return CollectionBlockDetailPage(collectionId: collectionId, block: block);
  }
}

class NoteDetailsPage extends StatelessWidget {
  const NoteDetailsPage({
    super.key,
    required this.collectionId,
    required this.block,
  });

  final String collectionId;
  final CollectionBlockEntity block;

  @override
  Widget build(BuildContext context) {
    return CollectionBlockDetailPage(collectionId: collectionId, block: block);
  }
}

class InputDetailsPage extends StatelessWidget {
  const InputDetailsPage({
    super.key,
    required this.collectionId,
    required this.block,
  });

  final String collectionId;
  final CollectionBlockEntity block;

  @override
  Widget build(BuildContext context) {
    return CollectionBlockDetailPage(collectionId: collectionId, block: block);
  }
}

class ChecklistDetailsPage extends StatelessWidget {
  const ChecklistDetailsPage({
    super.key,
    required this.collectionId,
    required this.block,
  });

  final String collectionId;
  final CollectionBlockEntity block;

  @override
  Widget build(BuildContext context) {
    return CollectionBlockDetailPage(collectionId: collectionId, block: block);
  }
}

class LinkDetailsPage extends StatelessWidget {
  const LinkDetailsPage({
    super.key,
    required this.collectionId,
    required this.block,
  });

  final String collectionId;
  final CollectionBlockEntity block;

  @override
  Widget build(BuildContext context) {
    return CollectionBlockDetailPage(collectionId: collectionId, block: block);
  }
}

class ImageDetailsPage extends StatelessWidget {
  const ImageDetailsPage({
    super.key,
    required this.collectionId,
    required this.block,
  });

  final String collectionId;
  final CollectionBlockEntity block;

  @override
  Widget build(BuildContext context) {
    return CollectionBlockDetailPage(collectionId: collectionId, block: block);
  }
}

class ExpenseDetailsPage extends StatelessWidget {
  const ExpenseDetailsPage({
    super.key,
    required this.collectionId,
    required this.block,
  });

  final String collectionId;
  final CollectionBlockEntity block;

  @override
  Widget build(BuildContext context) {
    return CollectionBlockDetailPage(collectionId: collectionId, block: block);
  }
}

class TimelineEventDetailsPage extends StatelessWidget {
  const TimelineEventDetailsPage({
    super.key,
    required this.collectionId,
    required this.block,
  });

  final String collectionId;
  final CollectionBlockEntity block;

  @override
  Widget build(BuildContext context) {
    return CollectionBlockDetailPage(collectionId: collectionId, block: block);
  }
}

class LocationDetailsPage extends StatelessWidget {
  const LocationDetailsPage({
    super.key,
    required this.collectionId,
    required this.block,
  });

  final String collectionId;
  final CollectionBlockEntity block;

  @override
  Widget build(BuildContext context) {
    return CollectionBlockDetailPage(collectionId: collectionId, block: block);
  }
}
