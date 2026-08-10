import 'package:pass_doc_manager/domain/profile/entities/profile_share_attribute.dart';

class GeneratedProfileShareLinkEntity {
  const GeneratedProfileShareLinkEntity({
    required this.vCard,
    required this.fileName,
    required this.expiresAt,
    required this.includedAttributes,
  });

  final String vCard;
  final String fileName;
  final DateTime expiresAt;
  final Set<ProfileShareAttribute> includedAttributes;

  // Kept for backwards compatibility with legacy "secure link" callers.
  String get url => vCard;
}
