import 'package:pass_doc_manager/core/usecase/usecase.dart';
import 'package:pass_doc_manager/domain/collections/entities/collection_entity.dart';
import 'package:pass_doc_manager/domain/collections/repositories/collections_repository.dart';

class GetCollectionDetail
    implements UseCase<CollectionEntity, GetCollectionDetailParams> {
  GetCollectionDetail(this._repository);

  final CollectionsRepository _repository;

  @override
  Future<CollectionEntity> call(GetCollectionDetailParams params) {
    return _repository.getCollectionById(collectionId: params.collectionId);
  }
}

class GetCollectionDetailParams {
  const GetCollectionDetailParams({required this.collectionId});

  final String collectionId;
}
