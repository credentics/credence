import 'package:pass_doc_manager/core/usecase/usecase.dart';
import 'package:pass_doc_manager/domain/bundles/entities/bundle_entity.dart';
import 'package:pass_doc_manager/domain/bundles/repositories/bundle_repository.dart';

class SaveBundle implements UseCase<BundleEntity, SaveBundleParams> {
  SaveBundle(this._repository);

  final BundleRepository _repository;

  @override
  Future<BundleEntity> call(SaveBundleParams params) {
    return _repository.saveBundle(params.bundle);
  }
}

class SaveBundleParams {
  const SaveBundleParams({required this.bundle});

  final BundleEntity bundle;
}
