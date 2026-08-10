import 'dart:convert';

import 'package:pass_doc_manager/data/vault_import/parsers/base_import_parser.dart';
import 'package:pass_doc_manager/domain/vault_import/entities/import_credential_entity.dart';

class BitwardenJsonParser extends BaseImportParser {
  @override
  List<ImportCredentialEntity> parse(String fileContent) {
    final credentials = <ImportCredentialEntity>[];

    try {
      final json = jsonDecode(fileContent) as Map<String, dynamic>;
      final items = json['items'] as List<dynamic>?;

      if (items == null) {
        return credentials;
      }

      for (final item in items) {
        try {
          final itemMap = item as Map<String, dynamic>;
          final type = itemMap['type'] as int?;

          // Only process logins (type == 1)
          if (type != 1) {
            continue;
          }

          final name = (itemMap['name'] as String?) ?? 'Unnamed';
          final login = itemMap['login'] as Map<String, dynamic>?;

          if (login == null) {
            continue;
          }

          final username = (login['username'] as String?) ?? '';
          final password = (login['password'] as String?) ?? '';
          final totp = login['totp'] as String?;
          final notes = (itemMap['notes'] as String?) ?? '';

          final uris = login['uris'] as List<dynamic>?;
          var url = '';
          if (uris != null && uris.isNotEmpty) {
            final firstUri = uris[0] as Map<String, dynamic>?;
            url = (firstUri?['uri'] as String?) ?? '';
          }

          credentials.add(
            ImportCredentialEntity(
              serviceName: name,
              username: username,
              password: password,
              url: url,
              notes: notes,
              totp: totp,
            ),
          );
        } catch (e) {
          // Skip malformed items
        }
      }
    } catch (e) {
      // JSON parsing failed
    }

    return credentials;
  }
}
