import 'package:pass_doc_manager/domain/documents/entities/document_category_type.dart';

class VaultDocumentEntity {
  const VaultDocumentEntity({
    required this.documentId,
    required this.documentName,
    required this.documentTypeLabel,
    required this.category,
    required this.updatedAt,
    required this.expiryDate,
  });

  final String documentId;
  final String documentName;
  final String documentTypeLabel;
  final DocumentCategoryType category;
  final DateTime updatedAt;
  final DateTime? expiryDate;
}
