import 'package:pass_doc_manager/core/usecase/usecase.dart';
import 'package:pass_doc_manager/domain/collections/entities/collection_entity.dart';
import 'package:pass_doc_manager/domain/collections/repositories/collections_repository.dart';

class GetCollections
    implements UseCase<List<CollectionEntity>, GetCollectionsParams> {
  GetCollections(this._repository);

  final CollectionsRepository _repository;

  @override
  Future<List<CollectionEntity>> call(GetCollectionsParams params) {
    return _repository.getCollections();
  }
}

class GetCollectionsParams {
  const GetCollectionsParams();
}
