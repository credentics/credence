import 'package:pass_doc_manager/core/usecase/usecase.dart';
import 'package:pass_doc_manager/domain/vault_portability/entities/export_vault_request_entity.dart';
import 'package:pass_doc_manager/domain/vault_portability/entities/export_vault_result_entity.dart';
import 'package:pass_doc_manager/domain/vault_portability/repositories/vault_portability_repository.dart';

class ExportVaultData
    implements UseCase<ExportVaultResultEntity, ExportVaultRequestEntity> {
  ExportVaultData(this._repository);

  final VaultPortabilityRepository _repository;

  @override
  Future<ExportVaultResultEntity> call(ExportVaultRequestEntity params) {
    return _repository.exportVault(params);
  }
}
