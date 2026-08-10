import 'package:pass_doc_manager/core/usecase/usecase.dart';
import 'package:pass_doc_manager/domain/documents/repositories/document_repository.dart';

class DeleteDocument implements UseCase<void, DeleteDocumentParams> {
  DeleteDocument(this._repository);

  final DocumentRepository _repository;

  @override
  Future<void> call(DeleteDocumentParams params) {
    return _repository.deleteDocument(documentId: params.documentId);
  }
}

class DeleteDocumentParams {
  const DeleteDocumentParams({required this.documentId});

  final String documentId;
}
