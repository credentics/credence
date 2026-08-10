import 'package:pass_doc_manager/core/usecase/usecase.dart';
import 'package:pass_doc_manager/domain/documents/repositories/document_repository.dart';

class SetPrimaryIdentityDocument
    implements UseCase<void, SetPrimaryIdentityDocumentParams> {
  SetPrimaryIdentityDocument(this._repository);

  final DocumentRepository _repository;

  @override
  Future<void> call(SetPrimaryIdentityDocumentParams params) {
    return _repository.setPrimaryIdentityDocument(
      documentId: params.documentId,
      isPrimary: params.isPrimary,
    );
  }
}

class SetPrimaryIdentityDocumentParams {
  const SetPrimaryIdentityDocumentParams({
    required this.documentId,
    this.isPrimary = true,
  });

  final String documentId;
  final bool isPrimary;
}
