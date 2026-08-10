import 'package:pass_doc_manager/core/usecase/usecase.dart';
import 'package:pass_doc_manager/domain/documents/entities/property_vault_entity.dart';
import 'package:pass_doc_manager/domain/documents/repositories/document_repository.dart';

class GetPropertyVaults
    implements UseCase<List<PropertyVaultEntity>, GetPropertyVaultsParams> {
  GetPropertyVaults(this._repository);

  final DocumentRepository _repository;

  @override
  Future<List<PropertyVaultEntity>> call(GetPropertyVaultsParams params) {
    return _repository.getPropertyVaults();
  }
}

class GetPropertyVaultsParams {
  const GetPropertyVaultsParams();
}
