import 'package:pass_doc_manager/core/usecase/usecase.dart';
import 'package:pass_doc_manager/domain/documents/entities/property_detail_entity.dart';
import 'package:pass_doc_manager/domain/documents/repositories/document_repository.dart';

class GetPropertyDetail
    implements UseCase<PropertyDetailEntity, GetPropertyDetailParams> {
  GetPropertyDetail(this._repository);

  final DocumentRepository _repository;

  @override
  Future<PropertyDetailEntity> call(GetPropertyDetailParams params) {
    return _repository.getPropertyDetail(propertyId: params.propertyId);
  }
}

class GetPropertyDetailParams {
  const GetPropertyDetailParams({required this.propertyId});

  final String propertyId;
}
