import 'package:pass_doc_manager/domain/credentials/entities/credential_security_status.dart';
import 'package:pass_doc_manager/domain/credentials/entities/credential_category.dart';

class CredentialSummaryEntity {
  const CredentialSummaryEntity({
    required this.id,
    required this.displayName,
    required this.username,
    required this.category,
    required this.brandHex,
    required this.status,
    this.logoPath,
    this.createdAt,
    this.lastUsedAt,
    this.breachedCount = 0,
    this.isFavorite = false,
    this.isReused = false,
    this.isMissingUrl = false,
  });

  final String id;
  final String displayName;
  final String username;
  final CredentialCategory category;
  final int brandHex;
  final CredentialSecurityStatus status;
  final String? logoPath;
  final DateTime? createdAt;
  final DateTime? lastUsedAt;
  final int breachedCount;
  final bool isFavorite;
  final bool isReused;
  final bool isMissingUrl;
}
