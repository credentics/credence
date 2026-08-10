import 'package:pass_doc_manager/domain/collections/entities/collection_entity.dart';

enum CollectionDetailViewStatus { initial, loading, ready, error }

class CollectionDetailState {
  const CollectionDetailState({
    required this.viewStatus,
    required this.collection,
    required this.errorMessage,
  });

  const CollectionDetailState.initial()
    : viewStatus = CollectionDetailViewStatus.initial,
      collection = null,
      errorMessage = null;

  final CollectionDetailViewStatus viewStatus;
  final CollectionEntity? collection;
  final String? errorMessage;

  CollectionDetailState copyWith({
    CollectionDetailViewStatus? viewStatus,
    CollectionEntity? collection,
    bool clearCollection = false,
    String? errorMessage,
    bool clearError = false,
  }) {
    return CollectionDetailState(
      viewStatus: viewStatus ?? this.viewStatus,
      collection: clearCollection ? null : (collection ?? this.collection),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}
