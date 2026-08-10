import 'package:pass_doc_manager/domain/credentials/repositories/credential_repository.dart';

class MarkCredentialUsed {
  MarkCredentialUsed(this._repository);

  final CredentialRepository _repository;

  Future<void> call({required String credentialId}) {
    return _repository.markCredentialUsed(id: credentialId);
  }
}
