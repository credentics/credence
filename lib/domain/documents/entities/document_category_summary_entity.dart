import 'package:pass_doc_manager/domain/documents/entities/document_category_type.dart';

class DocumentCategorySummaryEntity {
  const DocumentCategorySummaryEntity({
    required this.category,
    required this.documentsCount,
    required this.actionRequiredCount,
  });

  final DocumentCategoryType category;
  final int documentsCount;
  final int actionRequiredCount;

  bool get hasActionRequired => actionRequiredCount > 0;
}
