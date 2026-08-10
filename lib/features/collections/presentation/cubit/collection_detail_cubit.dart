import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pass_doc_manager/app/di/injection.dart';
import 'package:pass_doc_manager/domain/collections/entities/collection_block_entity.dart';
import 'package:pass_doc_manager/domain/collections/entities/collection_block_type.dart';
import 'package:pass_doc_manager/domain/collections/entities/collection_entity.dart';
import 'package:pass_doc_manager/domain/collections/usecases/delete_collection.dart';
import 'package:pass_doc_manager/domain/collections/usecases/delete_collection_block.dart';
import 'package:pass_doc_manager/domain/collections/usecases/get_collection_detail.dart';
import 'package:pass_doc_manager/domain/collections/usecases/save_collection.dart';
import 'package:pass_doc_manager/domain/collections/usecases/save_collection_block.dart';
import 'package:pass_doc_manager/domain/collections/usecases/cancel_collection_block_reminder.dart';
import 'package:pass_doc_manager/domain/collections/usecases/schedule_collection_block_reminder.dart';
import 'package:pass_doc_manager/features/collections/presentation/cubit/collection_detail_state.dart';

class CollectionDetailCubit extends Cubit<CollectionDetailState> {
  CollectionDetailCubit({
    GetCollectionDetail? getCollectionDetail,
    SaveCollectionBlock? saveCollectionBlock,
    DeleteCollectionBlock? deleteCollectionBlock,
    DeleteCollection? deleteCollection,
    SaveCollection? saveCollection,
    ScheduleCollectionBlockReminder? scheduleReminder,
    CancelCollectionBlockReminder? cancelReminder,
  }) : _getCollectionDetail = getCollectionDetail ?? getIt(),
       _saveCollectionBlock = saveCollectionBlock ?? getIt(),
       _deleteCollectionBlock = deleteCollectionBlock ?? getIt(),
       _deleteCollection = deleteCollection ?? getIt(),
       _saveCollection = saveCollection ?? getIt(),
       _scheduleReminder = scheduleReminder ?? getIt(),
       _cancelReminder = cancelReminder ?? getIt(),
       super(const CollectionDetailState.initial());

  final GetCollectionDetail _getCollectionDetail;
  final SaveCollectionBlock _saveCollectionBlock;
  final DeleteCollectionBlock _deleteCollectionBlock;
  final DeleteCollection _deleteCollection;
  final SaveCollection _saveCollection;
  final ScheduleCollectionBlockReminder _scheduleReminder;
  final CancelCollectionBlockReminder _cancelReminder;

  Future<void> load({required String collectionId}) async {
    emit(
      state.copyWith(
        viewStatus: CollectionDetailViewStatus.loading,
        clearError: true,
      ),
    );
    try {
      final detail = await _getCollectionDetail(
        GetCollectionDetailParams(collectionId: collectionId),
      );
      emit(
        state.copyWith(
          viewStatus: CollectionDetailViewStatus.ready,
          collection: detail,
          clearError: true,
        ),
      );
    } catch (_) {
      debugPrint('[CollectionDetail] Failed to load collection');
      emit(
        state.copyWith(
          viewStatus: CollectionDetailViewStatus.error,
          errorMessage: null, // UI uses l10n.collectionsErrorDetail
        ),
      );
    }
  }

  Future<void> saveBlock(CollectionBlockEntity block) async {
    final collection = state.collection;
    if (collection == null) return;

    await _saveCollectionBlock(
      SaveCollectionBlockParams(collectionId: collection.id, block: block),
    );

    // Schedule notification for reminder blocks
    if (block.type == CollectionBlockType.reminder && block.eventAt != null) {
      await _scheduleReminder(
        ScheduleCollectionBlockReminderParams(
          blockId: block.id,
          title: block.title,
          body: block.description.trim().isNotEmpty ? block.description : null,
          scheduledAt: block.eventAt!,
          repeatInterval: block.repeatInterval,
        ),
      );
    }

    await load(collectionId: collection.id);
  }

  Future<void> deleteBlock(String blockId) async {
    final collection = state.collection;
    if (collection == null) return;

    // Cancel notification if this is a reminder block
    final block = collection.blocks.where((b) => b.id == blockId).firstOrNull;
    if (block != null && block.type == CollectionBlockType.reminder) {
      await _cancelReminder(
        CancelCollectionBlockReminderParams(blockId: blockId),
      );
    }

    await _deleteCollectionBlock(
      DeleteCollectionBlockParams(
        collectionId: collection.id,
        blockId: blockId,
      ),
    );
    await load(collectionId: collection.id);
  }

  Future<void> duplicateBlock(String blockId) async {
    final collection = state.collection;
    if (collection == null) return;

    final block = collection.blocks.where((b) => b.id == blockId).firstOrNull;
    if (block == null) return;

    final now = DateTime.now();
    final newBlocks = <CollectionBlockEntity>[];

    String newId() => 'block_${now.microsecondsSinceEpoch}_${newBlocks.length}';

    // Duplicate the parent block itself.
    final parentNewId = newId();
    newBlocks.add(
      block.copyWith(
        id: parentNewId,
        title: '${block.title} (copy)',
        createdAt: now,
        updatedAt: now,
      ),
    );

    // Duplicate all children (recursive) for sections/folders.
    void duplicateChildren(String originalParentId, String newParentId) {
      final children = collection.blocks
          .where((b) => b.parentBlockId == originalParentId)
          .toList();
      for (final child in children) {
        final childNewId = newId();
        newBlocks.add(
          child.copyWith(
            id: childNewId,
            parentBlockId: newParentId,
            createdAt: now,
            updatedAt: now,
          ),
        );
        duplicateChildren(child.id, childNewId);
      }
    }

    duplicateChildren(blockId, parentNewId);

    // Save all duplicated blocks.
    for (final b in newBlocks) {
      await _saveCollectionBlock(
        SaveCollectionBlockParams(collectionId: collection.id, block: b),
      );
    }

    await load(collectionId: collection.id);
  }

  Future<void> saveCollection(CollectionEntity collection) async {
    await _saveCollection(SaveCollectionParams(collection: collection));
    await load(collectionId: collection.id);
  }

  Future<void> reorderBlocks({
    required String? parentBlockId,
    required int oldIndex,
    required int newIndex,
  }) async {
    final collection = state.collection;
    if (collection == null) return;

    final siblings =
        collection.blocks
            .where((b) => b.parentBlockId == parentBlockId)
            .toList()
          ..sort((a, b) => a.position.compareTo(b.position));

    if (oldIndex < 0 || oldIndex >= siblings.length || newIndex < 0) {
      return;
    }
    if (newIndex > oldIndex) {
      newIndex -= 1;
    }
    if (newIndex >= siblings.length || oldIndex == newIndex) {
      return;
    }

    final moved = siblings.removeAt(oldIndex);
    siblings.insert(newIndex, moved);

    final updatedIds = <String, int>{};
    for (var i = 0; i < siblings.length; i++) {
      if (siblings[i].position != i) {
        updatedIds[siblings[i].id] = i;
      }
    }

    if (updatedIds.isEmpty) return;

    final updatedBlocks = collection.blocks
        .map((b) {
          final newPos = updatedIds[b.id];
          return newPos != null ? b.copyWith(position: newPos) : b;
        })
        .toList(growable: false);

    final updated = collection.copyWith(
      blocks: updatedBlocks,
      updatedAt: DateTime.now(),
    );
    await _saveCollection(SaveCollectionParams(collection: updated));
    emit(state.copyWith(collection: updated));
  }

  Future<void> deleteCollection() async {
    final collection = state.collection;
    if (collection == null) return;
    await _deleteCollection(
      DeleteCollectionParams(collectionId: collection.id),
    );
  }
}
