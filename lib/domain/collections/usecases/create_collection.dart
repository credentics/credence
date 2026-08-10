import 'package:pass_doc_manager/core/usecase/usecase.dart';
import 'package:pass_doc_manager/domain/collections/entities/collection_entity.dart';
import 'package:pass_doc_manager/domain/collections/entities/collection_template_type.dart';
import 'package:pass_doc_manager/domain/collections/repositories/collections_repository.dart';

class CreateCollection
    implements UseCase<CollectionEntity, CreateCollectionParams> {
  CreateCollection(this._repository);

  final CollectionsRepository _repository;

  @override
  Future<CollectionEntity> call(CreateCollectionParams params) {
    return _repository.createCollection(
      name: params.name,
      iconKey: params.iconKey,
      iconEmoji: params.iconEmoji,
      iconImagePath: params.iconImagePath,
      accentColorHex: params.accentColorHex,
      template: params.template,
    );
  }
}

class CreateCollectionParams {
  const CreateCollectionParams({
    required this.name,
    required this.iconKey,
    this.iconEmoji,
    this.iconImagePath,
    required this.accentColorHex,
    required this.template,
  });

  final String name;
  final String iconKey;
  final String? iconEmoji;
  final String? iconImagePath;
  final String accentColorHex;
  final CollectionTemplateType template;
}
