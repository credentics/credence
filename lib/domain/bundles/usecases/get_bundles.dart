import 'package:pass_doc_manager/core/usecase/usecase.dart';
import 'package:pass_doc_manager/domain/bundles/entities/bundle_entity.dart';
import 'package:pass_doc_manager/domain/bundles/repositories/bundle_repository.dart';

class GetBundles implements UseCase<List<BundleEntity>, GetBundlesParams> {
  GetBundles(this._repository);

  final BundleRepository _repository;

  @override
  Future<List<BundleEntity>> call(GetBundlesParams params) {
    return _repository.getBundles();
  }
}

class GetBundlesParams {
  const GetBundlesParams();
}
