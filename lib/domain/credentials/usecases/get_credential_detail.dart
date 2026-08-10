import 'package:pass_doc_manager/domain/credentials/entities/credential_detail_entity.dart';
import 'package:pass_doc_manager/domain/credentials/repositories/credential_repository.dart';

class GetCredentialDetail {
  GetCredentialDetail(this._repository);

  final CredentialRepository _repository;

  Future<CredentialDetailEntity> call({required String credentialId}) {
    return _repository.getCredentialDetail(id: credentialId);
  }
}
