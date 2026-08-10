import 'package:pass_doc_manager/domain/secure_share/entities/share_payload_entity.dart';

class ShareLinkResult {
  const ShareLinkResult({
    required this.link,
    required this.expiresAt,
  });

  final String link;
  final DateTime expiresAt;
}

abstract class SecureShareRepository {
  /// Generates a secure share link for the given fields
  Future<ShareLinkResult> generateShareLink({
    required Map<String, String> fields,
    required String passphrase,
    required ShareTtl ttl,
  });

  /// Decrypts a share link with the given passphrase
  Future<Map<String, String>> decryptShareLink({
    required String encodedData,
    required String passphrase,
  });
}
