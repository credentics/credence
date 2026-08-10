import 'package:pass_doc_manager/domain/vault_import/entities/import_credential_entity.dart';

abstract class BaseImportParser {
  List<ImportCredentialEntity> parse(String fileContent);
}
