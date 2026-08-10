import 'package:pass_doc_manager/core/usecase/usecase.dart';
import 'package:pass_doc_manager/domain/documents/entities/document_detail_entity.dart';
import 'package:pass_doc_manager/domain/documents/repositories/document_repository.dart';

class ForceExpireDocument
    implements UseCase<DocumentDetailEntity, ForceExpireDocumentParams> {
  ForceExpireDocument(this._repository);

  final DocumentRepository _repository;

  @override
  Future<DocumentDetailEntity> call(ForceExpireDocumentParams params) {
    return _repository.forceExpireDocument(documentId: params.documentId);
  }
}

class ForceExpireDocumentParams {
  const ForceExpireDocumentParams({required this.documentId});

  final String documentId;
}
