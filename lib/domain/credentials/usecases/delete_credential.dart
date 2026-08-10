import 'package:pass_doc_manager/core/usecase/usecase.dart';
import 'package:pass_doc_manager/domain/credentials/repositories/credential_repository.dart';

class DeleteCredential implements UseCase<void, DeleteCredentialParams> {
  DeleteCredential(this._repository);
  final CredentialRepository _repository;

  @override
  Future<void> call(DeleteCredentialParams params) {
    return _repository.deleteCredential(id: params.id);
  }
}

class DeleteCredentialParams {
  const DeleteCredentialParams({required this.id});
  final String id;
}
