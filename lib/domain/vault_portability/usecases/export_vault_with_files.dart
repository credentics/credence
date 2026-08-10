import 'package:pass_doc_manager/core/usecase/usecase.dart';
import 'package:pass_doc_manager/domain/vault_portability/entities/export_vault_with_files_request_entity.dart';
import 'package:pass_doc_manager/domain/vault_portability/entities/export_vault_with_files_result_entity.dart';
import 'package:pass_doc_manager/domain/vault_portability/repositories/vault_portability_repository.dart';

class ExportVaultWithFiles
    implements
        UseCase<
          ExportVaultWithFilesResultEntity,
          ExportVaultWithFilesRequestEntity
        > {
  ExportVaultWithFiles(this._repository);

  final VaultPortabilityRepository _repository;

  @override
  Future<ExportVaultWithFilesResultEntity> call(
    ExportVaultWithFilesRequestEntity params,
  ) {
    return _repository.exportVaultWithFiles(params);
  }
}
