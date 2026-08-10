import 'package:pass_doc_manager/domain/credentials/entities/credential_category.dart';

class CredentialDetailEntity {
  const CredentialDetailEntity({
    required this.id,
    required this.serviceName,
    required this.accountLabel,
    required this.username,
    required this.category,
    required this.password,
    required this.url,
    required this.notes,
    required this.lastSecurityUpdate,
    required this.mfaRecovery,
    required this.isSecure,
    required this.brandHex,
    this.logoPath,
    this.breachedCount = 0,
    this.isFavorite = false,
  });

  final String id;
  final String serviceName;
  final String accountLabel;
  final String username;
  final CredentialCategory category;
  final String password;
  final String url;
  final String notes;
  final String lastSecurityUpdate;
  final String mfaRecovery;
  final bool isSecure;
  final int brandHex;
  final String? logoPath;
  final int breachedCount;
  final bool isFavorite;
}
