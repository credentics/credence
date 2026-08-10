import 'package:pass_doc_manager/core/usecase/usecase.dart';
import 'package:pass_doc_manager/domain/documents/entities/vault_document_entity.dart';
import 'package:pass_doc_manager/domain/documents/repositories/document_repository.dart';

class GetVaultDocuments
    implements UseCase<List<VaultDocumentEntity>, GetVaultDocumentsParams> {
  GetVaultDocuments(this._repository);

  final DocumentRepository _repository;

  @override
  Future<List<VaultDocumentEntity>> call(GetVaultDocumentsParams params) {
    return _repository.getVaultDocuments();
  }
}

class GetVaultDocumentsParams {
  const GetVaultDocumentsParams();
}
