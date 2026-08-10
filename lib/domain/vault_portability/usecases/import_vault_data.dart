import 'package:pass_doc_manager/core/usecase/usecase.dart';
import 'package:pass_doc_manager/domain/vault_portability/entities/import_vault_request_entity.dart';
import 'package:pass_doc_manager/domain/vault_portability/entities/import_vault_result_entity.dart';
import 'package:pass_doc_manager/domain/vault_portability/repositories/vault_portability_repository.dart';

class ImportVaultData
    implements UseCase<ImportVaultResultEntity, ImportVaultRequestEntity> {
  ImportVaultData(this._repository);

  final VaultPortabilityRepository _repository;

  @override
  Future<ImportVaultResultEntity> call(ImportVaultRequestEntity params) {
    return _repository.importVault(params);
  }
}
