import 'package:pass_doc_manager/domain/secure_share/entities/share_payload_entity.dart';
import 'package:pass_doc_manager/domain/secure_share/repositories/secure_share_repository.dart';

class CreateShareLinkParams {
  const CreateShareLinkParams({
    required this.itemType,
    required this.itemName,
    required this.fields,
    required this.passphrase,
    required this.ttl,
  });

  final ShareItemType itemType;
  final String itemName;
  final Map<String, String> fields;
  final String passphrase;
  final ShareTtl ttl;
}

class CreateShareLink {
  CreateShareLink(this._repository);

  final SecureShareRepository _repository;

  Future<ShareLinkResult> call(CreateShareLinkParams params) {
    return _repository.generateShareLink(
      fields: params.fields,
      passphrase: params.passphrase,
      ttl: params.ttl,
    );
  }
}
