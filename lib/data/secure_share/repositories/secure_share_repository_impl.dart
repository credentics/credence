import 'package:pass_doc_manager/data/secure_share/services/secure_share_service.dart';
import 'package:pass_doc_manager/domain/secure_share/entities/share_payload_entity.dart';
import 'package:pass_doc_manager/domain/secure_share/repositories/secure_share_repository.dart';

class SecureShareRepositoryImpl implements SecureShareRepository {
  SecureShareRepositoryImpl(this._service);

  final SecureShareService _service;

  @override
  Future<ShareLinkResult> generateShareLink({
    required Map<String, String> fields,
    required String passphrase,
    required ShareTtl ttl,
  }) {
    return _service.generateShareLink(
      fields: fields,
      passphrase: passphrase,
      ttl: ttl,
    );
  }

  @override
  Future<Map<String, String>> decryptShareLink({
    required String encodedData,
    required String passphrase,
  }) {
    return _service.decryptShareLink(
      encodedData: encodedData,
      passphrase: passphrase,
    );
  }
}
