import 'package:pass_doc_manager/core/usecase/usecase.dart';
import 'package:pass_doc_manager/domain/documents/repositories/document_repository.dart';

class ArchiveDocument implements UseCase<void, ArchiveDocumentParams> {
  ArchiveDocument(this._repository);

  final DocumentRepository _repository;

  @override
  Future<void> call(ArchiveDocumentParams params) {
    return _repository.archiveDocument(documentId: params.documentId);
  }
}

class ArchiveDocumentParams {
  const ArchiveDocumentParams({required this.documentId});

  final String documentId;
}
