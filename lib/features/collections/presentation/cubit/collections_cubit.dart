import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pass_doc_manager/app/di/injection.dart';
import 'package:pass_doc_manager/core/constants/internal_collection_ids.dart';
import 'package:pass_doc_manager/domain/collections/entities/collection_entity.dart';
import 'package:pass_doc_manager/domain/collections/entities/collection_template_type.dart';
import 'package:pass_doc_manager/domain/collections/usecases/create_collection.dart';
import 'package:pass_doc_manager/domain/collections/usecases/delete_collection.dart';
import 'package:pass_doc_manager/domain/collections/usecases/get_collections.dart';
import 'package:pass_doc_manager/domain/collections/usecases/reorder_collections.dart';
import 'package:pass_doc_manager/features/collections/presentation/cubit/collections_state.dart';

class CollectionsCubit extends Cubit<CollectionsState> {
  CollectionsCubit({
    GetCollections? getCollections,
    CreateCollection? createCollection,
    DeleteCollection? deleteCollection,
    ReorderCollections? reorderCollections,
  }) : _getCollections = getCollections ?? getIt(),
       _createCollection = createCollection ?? getIt(),
       _deleteCollection = deleteCollection ?? getIt(),
       _reorderCollections = reorderCollections ?? getIt(),
       super(const CollectionsState.initial());

  final GetCollections _getCollections;
  final CreateCollection _createCollection;
  final DeleteCollection _deleteCollection;
  final ReorderCollections _reorderCollections;

  Future<void> load() async {
    emit(
      state.copyWith(
        viewStatus: CollectionsViewStatus.loading,
        clearError: true,
      ),
    );
    try {
      final items = await _getCollections(const GetCollectionsParams());
      // Defense-in-depth for tests or alternate repositories.
      final visible = items
          .where((c) => c.id != internalSecureNotesCollectionId)
          .toList();
      emit(
        state.copyWith(
          viewStatus: CollectionsViewStatus.ready,
          collections: visible,
          isReorderMode: state.isReorderMode && visible.isNotEmpty,
          clearError: true,
        ),
      );
    } catch (_) {
      debugPrint('[Collections] Failed to load collections');
      emit(
        state.copyWith(
          viewStatus: CollectionsViewStatus.error,
          errorMessage: null, // UI uses l10n.collectionsErrorLoad
        ),
      );
    }
  }

  Future<CollectionEntity?> create({
    required String name,
    required String iconKey,
    String? iconEmoji,
    String? iconImagePath,
    required String accentColorHex,
    required CollectionTemplateType template,
  }) async {
    try {
      final created = await _createCollection(
        CreateCollectionParams(
          name: name,
          iconKey: iconKey,
          iconEmoji: iconEmoji,
          iconImagePath: iconImagePath,
          accentColorHex: accentColorHex,
          template: template,
        ),
      );
      await load();
      return created;
    } catch (_) {
      debugPrint('[Collections] Failed to create collection');
      emit(
        state.copyWith(
          viewStatus: CollectionsViewStatus.error,
          errorMessage: null, // UI uses l10n.collectionsErrorCreate
        ),
      );
      return null;
    }
  }

  Future<void> deleteCollection(String collectionId) async {
    try {
      await _deleteCollection(
        DeleteCollectionParams(collectionId: collectionId),
      );
      await load();
    } catch (_) {
      debugPrint('[Collections] Failed to delete collection');
      emit(
        state.copyWith(
          viewStatus: CollectionsViewStatus.error,
          errorMessage: null, // UI uses l10n.collectionsErrorDelete
        ),
      );
    }
  }

  void setReorderMode(bool enabled) {
    if (state.isReorderMode == enabled) {
      return;
    }
    emit(state.copyWith(isReorderMode: enabled));
  }

  Future<void> reorderCollections({
    required int oldIndex,
    required int newIndex,
  }) async {
    final collections = state.collections.toList(growable: true);
    if (oldIndex < 0 ||
        oldIndex >= collections.length ||
        newIndex < 0 ||
        newIndex >= collections.length) {
      return;
    }

    final moved = collections.removeAt(oldIndex);
    collections.insert(newIndex, moved);
    final reordered = [
      for (var i = 0; i < collections.length; i++)
        collections[i].copyWith(position: i),
    ];
    emit(state.copyWith(collections: reordered, clearError: true));

    try {
      await _reorderCollections(
        ReorderCollectionsParams(
          orderedCollectionIds: reordered.map((item) => item.id).toList(),
        ),
      );
    } catch (_) {
      debugPrint('[Collections] Failed to reorder collections');
      await load();
      emit(
        state.copyWith(
          viewStatus: CollectionsViewStatus.error,
          errorMessage: null,
        ),
      );
    }
  }
}
