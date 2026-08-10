import 'package:pass_doc_manager/core/usecase/usecase.dart';
import 'package:pass_doc_manager/domain/collections/repositories/collections_repository.dart';

class DeleteCollectionBlock
    implements UseCase<void, DeleteCollectionBlockParams> {
  DeleteCollectionBlock(this._repository);

  final CollectionsRepository _repository;

  @override
  Future<void> call(DeleteCollectionBlockParams params) {
    return _repository.deleteBlock(
      collectionId: params.collectionId,
      blockId: params.blockId,
    );
  }
}

class DeleteCollectionBlockParams {
  const DeleteCollectionBlockParams({
    required this.collectionId,
    required this.blockId,
  });

  final String collectionId;
  final String blockId;
}
