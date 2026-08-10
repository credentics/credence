import 'package:pass_doc_manager/core/usecase/usecase.dart';
import 'package:pass_doc_manager/domain/documents/entities/document_detail_entity.dart';
import 'package:pass_doc_manager/domain/documents/repositories/document_repository.dart';

class GetDocumentDetail
    implements UseCase<DocumentDetailEntity, GetDocumentDetailParams> {
  GetDocumentDetail(this._repository);

  final DocumentRepository _repository;

  @override
  Future<DocumentDetailEntity> call(GetDocumentDetailParams params) {
    return _repository.getDocumentDetail(documentId: params.documentId);
  }
}

class GetDocumentDetailParams {
  const GetDocumentDetailParams({required this.documentId});

  final String documentId;
}
