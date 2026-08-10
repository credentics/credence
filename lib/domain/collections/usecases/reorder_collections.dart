import 'package:pass_doc_manager/core/usecase/usecase.dart';
import 'package:pass_doc_manager/domain/collections/repositories/collections_repository.dart';

class ReorderCollections implements UseCase<void, ReorderCollectionsParams> {
  ReorderCollections(this._repository);

  final CollectionsRepository _repository;

  @override
  Future<void> call(ReorderCollectionsParams params) {
    return _repository.reorderCollections(
      orderedCollectionIds: params.orderedCollectionIds,
    );
  }
}

class ReorderCollectionsParams {
  const ReorderCollectionsParams({required this.orderedCollectionIds});

  final List<String> orderedCollectionIds;
}
