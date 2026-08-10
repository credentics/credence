import 'package:pass_doc_manager/core/usecase/usecase.dart';
import 'package:pass_doc_manager/domain/collections/entities/collection_block_entity.dart';
import 'package:pass_doc_manager/domain/collections/repositories/collections_repository.dart';

class SaveCollectionBlock implements UseCase<void, SaveCollectionBlockParams> {
  SaveCollectionBlock(this._repository);

  final CollectionsRepository _repository;

  @override
  Future<void> call(SaveCollectionBlockParams params) {
    return _repository.saveBlock(
      collectionId: params.collectionId,
      block: params.block,
    );
  }
}

class SaveCollectionBlockParams {
  const SaveCollectionBlockParams({
    required this.collectionId,
    required this.block,
  });

  final String collectionId;
  final CollectionBlockEntity block;
}
