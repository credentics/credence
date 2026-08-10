import 'package:pass_doc_manager/core/usecase/usecase.dart';
import 'package:pass_doc_manager/domain/collections/repositories/collections_repository.dart';

class DeleteCollection
    implements UseCase<void, DeleteCollectionParams> {
  DeleteCollection(this._repository);

  final CollectionsRepository _repository;

  @override
  Future<void> call(DeleteCollectionParams params) {
    return _repository.deleteCollection(collectionId: params.collectionId);
  }
}

class DeleteCollectionParams {
  const DeleteCollectionParams({required this.collectionId});

  final String collectionId;
}
