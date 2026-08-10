import 'package:pass_doc_manager/core/usecase/usecase.dart';
import 'package:pass_doc_manager/domain/bundles/repositories/bundle_repository.dart';

class DeleteBundle implements UseCase<void, DeleteBundleParams> {
  DeleteBundle(this._repository);

  final BundleRepository _repository;

  @override
  Future<void> call(DeleteBundleParams params) {
    return _repository.deleteBundle(bundleId: params.bundleId);
  }
}

class DeleteBundleParams {
  const DeleteBundleParams({required this.bundleId});

  final String bundleId;
}
