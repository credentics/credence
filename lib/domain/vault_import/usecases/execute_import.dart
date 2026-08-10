import 'package:pass_doc_manager/data/credentials/datasources/local/credential_local_data_source.dart';
import 'package:pass_doc_manager/data/credentials/dtos/credential_create_dto.dart';
import 'package:pass_doc_manager/domain/credentials/entities/credential_category.dart';
import 'package:pass_doc_manager/domain/vault_import/entities/import_credential_entity.dart';
import 'package:pass_doc_manager/domain/vault_import/entities/import_result_entity.dart';

class ExecuteImport {
  ExecuteImport(this._dataSource);

  final CredentialLocalDataSource _dataSource;

  Future<ImportResultEntity> call({
    required List<ImportCredentialEntity> credentials,
  }) async {
    final errorMessages = <String>[];
    var importedCount = 0;

    for (final credential in credentials) {
      // Skip deselected items
      if (!credential.isSelected) {
        continue;
      }

      try {
        await _dataSource.createCredential(
          draft: CredentialCreateDto(
            serviceName: credential.serviceName.trim(),
            accountLabel: 'Imported Account',
            username: credential.username.trim(),
            categoryKey: CredentialCategory.general.storageKey,
            password: credential.password,
            url: credential.url.trim(),
            notes: credential.notes.trim(),
            brandHex: 0x2A1464, // Default brand hex
            logoPath: null,
          ),
        );
        importedCount++;
      } catch (e) {
        errorMessages.add(
          '${credential.serviceName}: ${e.toString()}',
        );
      }
    }

    final skippedDuplicates = credentials
        .where((c) => c.isDuplicate && !c.isSelected)
        .length;

    return ImportResultEntity(
      totalParsed: credentials.length,
      imported: importedCount,
      skippedDuplicates: skippedDuplicates,
      errors: errorMessages.length,
      errorMessages: errorMessages,
    );
  }
}
