import 'package:pass_doc_manager/core/usecase/usecase.dart';
import 'package:pass_doc_manager/domain/documents/entities/work_company_vault_entity.dart';
import 'package:pass_doc_manager/domain/documents/repositories/document_repository.dart';

class GetWorkCompanyVaults
    implements
        UseCase<List<WorkCompanyVaultEntity>, GetWorkCompanyVaultsParams> {
  GetWorkCompanyVaults(this._repository);

  final DocumentRepository _repository;

  @override
  Future<List<WorkCompanyVaultEntity>> call(GetWorkCompanyVaultsParams params) {
    return _repository.getWorkCompanyVaults();
  }
}

class GetWorkCompanyVaultsParams {
  const GetWorkCompanyVaultsParams();
}
