import 'package:pass_doc_manager/core/usecase/usecase.dart';
import 'package:pass_doc_manager/domain/bundles/entities/bundle_entity.dart';
import 'package:pass_doc_manager/domain/bundles/repositories/bundle_repository.dart';

class GetBundleDetail
    implements UseCase<BundleEntity, GetBundleDetailParams> {
  GetBundleDetail(this._repository);

  final BundleRepository _repository;

  @override
  Future<BundleEntity> call(GetBundleDetailParams params) {
    return _repository.getBundleById(bundleId: params.bundleId);
  }
}

class GetBundleDetailParams {
  const GetBundleDetailParams({required this.bundleId});

  final String bundleId;
}
