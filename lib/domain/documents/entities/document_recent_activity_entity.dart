import 'package:pass_doc_manager/domain/documents/entities/document_category_type.dart';

class DocumentRecentActivityEntity {
  const DocumentRecentActivityEntity({
    required this.documentId,
    required this.fileName,
    required this.category,
    required this.updatedAt,
    this.filesCount = 1,
  });

  final String documentId;
  final String fileName;
  final DocumentCategoryType category;
  final DateTime updatedAt;
  final int filesCount;
}
