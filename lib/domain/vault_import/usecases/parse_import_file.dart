import 'package:pass_doc_manager/data/vault_import/parsers/base_import_parser.dart';
import 'package:pass_doc_manager/data/vault_import/parsers/bitwarden_json_parser.dart';
import 'package:pass_doc_manager/data/vault_import/parsers/chrome_csv_parser.dart';
import 'package:pass_doc_manager/data/vault_import/parsers/lastpass_csv_parser.dart';
import 'package:pass_doc_manager/data/vault_import/parsers/onepassword_csv_parser.dart';
import 'package:pass_doc_manager/data/vault_import/parsers/safari_csv_parser.dart';
import 'package:pass_doc_manager/domain/vault_import/entities/import_credential_entity.dart';
import 'package:pass_doc_manager/domain/vault_import/entities/import_source.dart';

class ParseImportFile {
  ParseImportFile();

  List<ImportCredentialEntity> call({
    required ImportSource source,
    required String fileContent,
  }) {
    final parser = _getParser(source);
    return parser.parse(fileContent);
  }

  BaseImportParser _getParser(ImportSource source) {
    return switch (source) {
      ImportSource.onePassword => OnePasswordCsvParser(),
      ImportSource.bitwarden => BitwardenJsonParser(),
      ImportSource.chrome => ChromeCsvParser(),
      ImportSource.safari => SafariCsvParser(),
      ImportSource.lastPass => LastPassCsvParser(),
    };
  }
}
