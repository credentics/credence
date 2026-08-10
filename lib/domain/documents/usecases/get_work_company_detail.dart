import 'package:pass_doc_manager/core/usecase/usecase.dart';
import 'package:pass_doc_manager/domain/documents/entities/work_company_detail_entity.dart';
import 'package:pass_doc_manager/domain/documents/repositories/document_repository.dart';

class GetWorkCompanyDetail
    implements UseCase<WorkCompanyDetailEntity, GetWorkCompanyDetailParams> {
  GetWorkCompanyDetail(this._repository);

  final DocumentRepository _repository;

  @override
  Future<WorkCompanyDetailEntity> call(GetWorkCompanyDetailParams params) {
    return _repository.getWorkCompanyDetail(companyId: params.companyId);
  }
}

class GetWorkCompanyDetailParams {
  const GetWorkCompanyDetailParams({required this.companyId});

  final String companyId;
}
