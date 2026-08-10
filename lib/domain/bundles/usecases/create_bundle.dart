import 'package:pass_doc_manager/core/usecase/usecase.dart';
import 'package:pass_doc_manager/domain/bundles/entities/bundle_entity.dart';
import 'package:pass_doc_manager/domain/bundles/repositories/bundle_repository.dart';

class CreateBundle implements UseCase<BundleEntity, CreateBundleParams> {
  CreateBundle(this._repository);

  final BundleRepository _repository;

  @override
  Future<BundleEntity> call(CreateBundleParams params) {
    return _repository.createBundle(
      title: params.title,
      purpose: params.purpose,
      description: params.description,
      templateKey: params.templateKey,
    );
  }
}

class CreateBundleParams {
  const CreateBundleParams({
    required this.title,
    this.purpose,
    this.description,
    this.templateKey,
  });

  final String title;
  final String? purpose;
  final String? description;
  final String? templateKey;
}
