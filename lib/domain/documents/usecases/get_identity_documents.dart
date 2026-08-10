import 'package:pass_doc_manager/core/usecase/usecase.dart';
import 'package:pass_doc_manager/domain/documents/entities/identity_document_entity.dart';
import 'package:pass_doc_manager/domain/documents/repositories/document_repository.dart';

class GetIdentityDocuments
    implements
        UseCase<List<IdentityDocumentEntity>, GetIdentityDocumentsParams> {
  GetIdentityDocuments(this._repository);

  final DocumentRepository _repository;

  @override
  Future<List<IdentityDocumentEntity>> call(GetIdentityDocumentsParams params) {
    return _repository.getIdentityDocuments();
  }
}

class GetIdentityDocumentsParams {
  const GetIdentityDocumentsParams();
}
