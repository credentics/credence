import 'package:pass_doc_manager/data/vault_portability/dtos/import_apply_result_dto.dart';
import 'package:pass_doc_manager/data/vault_portability/dtos/vault_document_record_dto.dart';
import 'package:pass_doc_manager/data/vault_portability/dtos/vault_password_record_dto.dart';
import 'package:pass_doc_manager/domain/vault_portability/entities/import_vault_result_entity.dart';
import 'package:pass_doc_manager/domain/vault_portability/entities/vault_document_record_entity.dart';
import 'package:pass_doc_manager/domain/vault_portability/entities/vault_password_record_entity.dart';

extension VaultDocumentRecordDtoMapper on VaultDocumentRecordDto {
  VaultDocumentRecordEntity toEntity() {
    return VaultDocumentRecordEntity(
      id: id,
      title: title,
      category: category,
      updatedAtIso: updatedAtIso,
    );
  }
}

extension VaultPasswordRecordDtoMapper on VaultPasswordRecordDto {
  VaultPasswordRecordEntity toEntity() {
    return VaultPasswordRecordEntity(
      id: id,
      serviceName: serviceName,
      username: username,
      secret: secret,
      updatedAtIso: updatedAtIso,
    );
  }
}

extension VaultDocumentRecordEntityMapper on VaultDocumentRecordEntity {
  VaultDocumentRecordDto toDto() {
    return VaultDocumentRecordDto(
      id: id,
      title: title,
      category: category,
      updatedAtIso: updatedAtIso,
    );
  }
}

extension VaultPasswordRecordEntityMapper on VaultPasswordRecordEntity {
  VaultPasswordRecordDto toDto() {
    return VaultPasswordRecordDto(
      id: id,
      serviceName: serviceName,
      username: username,
      secret: secret,
      updatedAtIso: updatedAtIso,
    );
  }
}

extension ImportApplyResultDtoMapper on ImportApplyResultDto {
  ImportVaultResultEntity toEntity() {
    return ImportVaultResultEntity(
      importedDocuments: importedDocuments,
      importedPasswords: importedPasswords,
      updatedDocuments: updatedDocuments,
      updatedPasswords: updatedPasswords,
    );
  }
}
