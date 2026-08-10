import 'package:pass_doc_manager/core/usecase/usecase.dart';
import 'package:pass_doc_manager/domain/documents/entities/property_asset_record_entity.dart';
import 'package:pass_doc_manager/domain/documents/entities/property_asset_type.dart';
import 'package:pass_doc_manager/domain/documents/repositories/document_repository.dart';

class GetPropertyAssetRecords
    implements
        UseCase<
          List<PropertyAssetRecordEntity>,
          GetPropertyAssetRecordsParams
        > {
  GetPropertyAssetRecords(this._repository);

  final DocumentRepository _repository;

  @override
  Future<List<PropertyAssetRecordEntity>> call(
    GetPropertyAssetRecordsParams params,
  ) {
    return _repository.getPropertyAssetRecords(
      propertyId: params.propertyId,
      assetType: params.assetType,
    );
  }
}

class GetPropertyAssetRecordsParams {
  const GetPropertyAssetRecordsParams({
    required this.propertyId,
    this.assetType,
  });

  final String propertyId;
  final PropertyAssetType? assetType;
}
