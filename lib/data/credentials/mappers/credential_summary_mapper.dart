import 'package:pass_doc_manager/data/credentials/dtos/credential_summary_dto.dart';
import 'package:pass_doc_manager/domain/credentials/entities/credential_category.dart';
import 'package:pass_doc_manager/domain/credentials/entities/credential_security_status.dart';
import 'package:pass_doc_manager/domain/credentials/entities/credential_summary_entity.dart';

extension CredentialSummaryMapper on CredentialSummaryDto {
  CredentialSummaryEntity toEntity() {
    return CredentialSummaryEntity(
      id: id,
      displayName: displayName,
      username: username,
      category: parseCredentialCategory(categoryKey),
      brandHex: brandHex,
      logoPath: logoPath,
      createdAt: DateTime.tryParse(createdAtIso ?? '')?.toLocal(),
      lastUsedAt: DateTime.tryParse(lastUsedAtIso ?? '')?.toLocal(),
      status: hasWarning
          ? CredentialSecurityStatus.warning
          : CredentialSecurityStatus.secure,
      breachedCount: breachedCount,
      isFavorite: isFavorite,
      isReused: isReused,
      isMissingUrl: isMissingUrl,
    );
  }
}
