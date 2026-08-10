import 'package:pass_doc_manager/core/usecase/usecase.dart';
import 'package:pass_doc_manager/domain/documents/entities/document_capture_source.dart';
import 'package:pass_doc_manager/domain/documents/entities/document_detail_entity.dart';
import 'package:pass_doc_manager/domain/documents/repositories/document_repository.dart';

class ReplaceDocumentCapture
    implements UseCase<DocumentDetailEntity, ReplaceDocumentCaptureParams> {
  ReplaceDocumentCapture(this._repository);

  final DocumentRepository _repository;

  @override
  Future<DocumentDetailEntity> call(ReplaceDocumentCaptureParams params) {
    return _repository.replaceDocumentCapture(
      documentId: params.documentId,
      source: params.source,
      scanPagesCount: params.scanPagesCount,
    );
  }
}

class ReplaceDocumentCaptureParams {
  const ReplaceDocumentCaptureParams({
    required this.documentId,
    required this.source,
    required this.scanPagesCount,
  });

  final String documentId;
  final DocumentCaptureSource source;
  final int scanPagesCount;
}
