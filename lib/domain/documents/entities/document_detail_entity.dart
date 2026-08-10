import 'package:pass_doc_manager/domain/documents/entities/document_capture_source.dart';
import 'package:pass_doc_manager/domain/documents/entities/document_category_type.dart';
import 'package:pass_doc_manager/domain/documents/entities/document_structured_field_entity.dart';
import 'package:pass_doc_manager/domain/documents/entities/document_type.dart';
import 'package:pass_doc_manager/domain/documents/entities/identity_document_status.dart';

class DocumentDetailEntity {
  const DocumentDetailEntity({
    required this.id,
    required this.type,
    required this.category,
    required this.screenTitle,
    required this.issuer,
    required this.fileName,
    required this.structuredFields,
    required this.tags,
    required this.uploadDate,
    required this.fileSizeLabel,
    required this.isVerifiedScan,
    required this.isFavorite,
    required this.isPrimary,
    required this.status,
    required this.captureSource,
    required this.scanPagesCount,
    required this.referenceFilesCount,
    required this.updatedAt,
    required this.expiryDate,
  });

  final String id;
  final DocumentType type;
  final DocumentCategoryType category;
  final String screenTitle;
  final String issuer;
  final String fileName;
  final List<DocumentStructuredFieldEntity> structuredFields;
  final List<String> tags;
  final DateTime uploadDate;
  final String fileSizeLabel;
  final bool isVerifiedScan;
  final bool isFavorite;
  final bool isPrimary;
  final IdentityDocumentStatus status;
  final DocumentCaptureSource captureSource;
  final int scanPagesCount;
  final int referenceFilesCount;
  final DateTime updatedAt;
  final DateTime? expiryDate;
}
