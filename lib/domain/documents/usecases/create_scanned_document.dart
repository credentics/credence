import 'package:pass_doc_manager/core/usecase/usecase.dart';
import 'package:pass_doc_manager/domain/documents/entities/document_capture_source.dart';
import 'package:pass_doc_manager/domain/documents/entities/document_category_type.dart';
import 'package:pass_doc_manager/domain/documents/entities/document_detail_entity.dart';
import 'package:pass_doc_manager/domain/documents/entities/document_type.dart';
import 'package:pass_doc_manager/domain/documents/repositories/document_repository.dart';

class CreateScannedDocument
    implements UseCase<DocumentDetailEntity, CreateScannedDocumentParams> {
  CreateScannedDocument(this._repository);

  final DocumentRepository _repository;

  @override
  Future<DocumentDetailEntity> call(CreateScannedDocumentParams params) {
    return _repository.createScannedDocument(
      type: params.type,
      source: params.source,
      scanPagesCount: params.scanPagesCount,
      categoryOverride: params.categoryOverride,
      documentTypeKeyOverride: params.documentTypeKeyOverride,
      issuerOverride: params.issuerOverride,
      identifierLabelOverride: params.identifierLabelOverride,
      identifierValueOverride: params.identifierValueOverride,
      expiryDateOverride: params.expiryDateOverride,
      structuredFieldsOverride: params.structuredFieldsOverride,
      tagsOverride: params.tagsOverride,
    );
  }
}

class CreateScannedDocumentParams {
  const CreateScannedDocumentParams({
    required this.type,
    required this.source,
    required this.scanPagesCount,
    this.categoryOverride,
    this.documentTypeKeyOverride,
    this.issuerOverride,
    this.identifierLabelOverride,
    this.identifierValueOverride,
    this.expiryDateOverride,
    this.structuredFieldsOverride,
    this.tagsOverride,
  });

  final DocumentType type;
  final DocumentCaptureSource source;
  final int scanPagesCount;
  final DocumentCategoryType? categoryOverride;
  final String? documentTypeKeyOverride;
  final String? issuerOverride;
  final String? identifierLabelOverride;
  final String? identifierValueOverride;
  final DateTime? expiryDateOverride;
  final List<Map<String, String>>? structuredFieldsOverride;
  final List<String>? tagsOverride;
}
