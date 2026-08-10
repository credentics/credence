import 'package:pass_doc_manager/data/vault_import/parsers/base_import_parser.dart';
import 'package:pass_doc_manager/domain/vault_import/entities/import_credential_entity.dart';

class ChromeCsvParser extends BaseImportParser {
  @override
  List<ImportCredentialEntity> parse(String fileContent) {
    final lines = fileContent.split('\n');
    final credentials = <ImportCredentialEntity>[];

    // Skip header row (name,url,username,password,note)
    for (var i = 1; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;

      try {
        final fields = _parseCSVLine(line);
        if (fields.length < 5) continue;

        credentials.add(
          ImportCredentialEntity(
            serviceName: fields[0].trim(),
            username: fields[2].trim(),
            password: fields[3].trim(),
            url: fields[1].trim(),
            notes: fields[4].trim(),
          ),
        );
      } catch (e) {
        // Skip malformed lines
      }
    }

    return credentials;
  }

  List<String> _parseCSVLine(String line) {
    final fields = <String>[];
    var current = StringBuffer();
    var inQuotes = false;

    for (var i = 0; i < line.length; i++) {
      final char = line[i];

      if (char == '"') {
        inQuotes = !inQuotes;
      } else if (char == ',' && !inQuotes) {
        fields.add(current.toString());
        current = StringBuffer();
      } else {
        current.write(char);
      }
    }

    fields.add(current.toString());
    return fields;
  }
}
