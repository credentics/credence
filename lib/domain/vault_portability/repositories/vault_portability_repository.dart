import 'package:pass_doc_manager/domain/vault_portability/entities/export_vault_request_entity.dart';
import 'package:pass_doc_manager/domain/vault_portability/entities/export_vault_result_entity.dart';
import 'package:pass_doc_manager/domain/vault_portability/entities/export_vault_with_files_request_entity.dart';
import 'package:pass_doc_manager/domain/vault_portability/entities/export_vault_with_files_result_entity.dart';
import 'package:pass_doc_manager/domain/vault_portability/entities/import_vault_request_entity.dart';
import 'package:pass_doc_manager/domain/vault_portability/entities/import_vault_result_entity.dart';
import 'package:pass_doc_manager/domain/vault_portability/entities/vault_portability_policy_entity.dart';

abstract class VaultPortabilityRepository {
  Future<ExportVaultResultEntity> exportVault(ExportVaultRequestEntity request);

  Future<ExportVaultWithFilesResultEntity> exportVaultWithFiles(
    ExportVaultWithFilesRequestEntity request,
  );

  Future<ImportVaultResultEntity> importVault(ImportVaultRequestEntity request);

  Future<VaultPortabilityPolicyEntity> getPortabilityPolicy();
}
