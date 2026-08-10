import 'package:pass_doc_manager/core/usecase/usecase.dart';
import 'package:pass_doc_manager/domain/collections/entities/collection_entity.dart';
import 'package:pass_doc_manager/domain/collections/repositories/collections_repository.dart';

class SaveCollection implements UseCase<void, SaveCollectionParams> {
  SaveCollection(this._repository);

  final CollectionsRepository _repository;

  @override
  Future<void> call(SaveCollectionParams params) {
    return _repository.saveCollection(params.collection);
  }
}

class SaveCollectionParams {
  const SaveCollectionParams({required this.collection});

  final CollectionEntity collection;
}
