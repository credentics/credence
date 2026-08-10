import 'package:pass_doc_manager/core/usecase/usecase.dart';
import 'package:pass_doc_manager/domain/bundles/entities/bundle_entity.dart';
import 'package:pass_doc_manager/domain/bundles/repositories/bundle_repository.dart';

class RemoveItemFromBundle
    implements UseCase<BundleEntity, RemoveItemFromBundleParams> {
  RemoveItemFromBundle(this._repository);

  final BundleRepository _repository;

  @override
  Future<BundleEntity> call(RemoveItemFromBundleParams params) {
    return _repository.removeItem(
      bundleId: params.bundleId,
      itemId: params.itemId,
    );
  }
}

class RemoveItemFromBundleParams {
  const RemoveItemFromBundleParams({
    required this.bundleId,
    required this.itemId,
  });

  final String bundleId;
  final String itemId;
}
