import 'package:pass_doc_manager/domain/credentials/entities/credential_category.dart';

class CredentialDraftEntity {
  const CredentialDraftEntity({
    required this.serviceName,
    required this.accountLabel,
    required this.username,
    required this.category,
    required this.password,
    required this.url,
    required this.notes,
    required this.brandHex,
    this.logoPath,
  });

  final String serviceName;
  final String accountLabel;
  final String username;
  final CredentialCategory category;
  final String password;
  final String url;
  final String notes;
  final int brandHex;
  final String? logoPath;
}
