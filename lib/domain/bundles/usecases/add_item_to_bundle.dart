import 'package:pass_doc_manager/core/usecase/usecase.dart';
import 'package:pass_doc_manager/domain/bundles/entities/bundle_entity.dart';
import 'package:pass_doc_manager/domain/bundles/entities/bundle_item_ref.dart';
import 'package:pass_doc_manager/domain/bundles/repositories/bundle_repository.dart';

class AddItemToBundle
    implements UseCase<BundleEntity, AddItemToBundleParams> {
  AddItemToBundle(this._repository);

  final BundleRepository _repository;

  @override
  Future<BundleEntity> call(AddItemToBundleParams params) {
    return _repository.addItem(
      bundleId: params.bundleId,
      item: params.item,
    );
  }
}

class AddItemToBundleParams {
  const AddItemToBundleParams({required this.bundleId, required this.item});

  final String bundleId;
  final BundleItemRef item;
}
