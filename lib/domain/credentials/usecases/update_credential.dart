import 'package:pass_doc_manager/domain/credentials/entities/credential_detail_entity.dart';
import 'package:pass_doc_manager/domain/credentials/entities/credential_draft_entity.dart';
import 'package:pass_doc_manager/domain/credentials/repositories/credential_repository.dart';

class UpdateCredential {
  UpdateCredential(this._repository);

  final CredentialRepository _repository;

  Future<CredentialDetailEntity> call({
    required String credentialId,
    required CredentialDraftEntity draft,
  }) {
    return _repository.updateCredential(id: credentialId, draft: draft);
  }
}
