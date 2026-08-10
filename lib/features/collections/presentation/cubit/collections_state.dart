import 'package:pass_doc_manager/domain/collections/entities/collection_entity.dart';

enum CollectionsViewStatus { initial, loading, ready, error }

class CollectionsState {
  const CollectionsState({
    required this.viewStatus,
    required this.collections,
    required this.isReorderMode,
    required this.errorMessage,
  });

  const CollectionsState.initial()
    : viewStatus = CollectionsViewStatus.initial,
      collections = const <CollectionEntity>[],
      isReorderMode = false,
      errorMessage = null;

  final CollectionsViewStatus viewStatus;
  final List<CollectionEntity> collections;
  final bool isReorderMode;
  final String? errorMessage;

  CollectionsState copyWith({
    CollectionsViewStatus? viewStatus,
    List<CollectionEntity>? collections,
    bool? isReorderMode,
    String? errorMessage,
    bool clearError = false,
  }) {
    return CollectionsState(
      viewStatus: viewStatus ?? this.viewStatus,
      collections: collections ?? this.collections,
      isReorderMode: isReorderMode ?? this.isReorderMode,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}
