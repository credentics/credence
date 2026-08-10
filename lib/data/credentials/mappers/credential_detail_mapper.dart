import 'package:pass_doc_manager/data/credentials/dtos/credential_detail_dto.dart';
import 'package:pass_doc_manager/domain/credentials/entities/credential_category.dart';
import 'package:pass_doc_manager/domain/credentials/entities/credential_detail_entity.dart';

extension CredentialDetailMapper on CredentialDetailDto {
  CredentialDetailEntity toEntity() {
    return CredentialDetailEntity(
      id: id,
      serviceName: serviceName,
      accountLabel: accountLabel,
      username: username,
      category: parseCredentialCategory(categoryKey),
      password: password,
      url: url,
      notes: notes,
      lastSecurityUpdate: lastSecurityUpdate,
      mfaRecovery: mfaRecovery,
      isSecure: isSecure,
      brandHex: brandHex,
      logoPath: logoPath,
      breachedCount: breachedCount,
      isFavorite: isFavorite,
    );
  }
}
