import 'package:pass_doc_manager/domain/documents/entities/document_category_summary_entity.dart';
import 'package:pass_doc_manager/domain/documents/entities/document_recent_activity_entity.dart';

class DocumentLibraryOverviewEntity {
  const DocumentLibraryOverviewEntity({
    required this.categories,
    required this.recentActivity,
    required this.attentionDocumentsCount,
    required this.totalDocumentsCount,
  });

  final List<DocumentCategorySummaryEntity> categories;
  final List<DocumentRecentActivityEntity> recentActivity;
  final int attentionDocumentsCount;
  final int totalDocumentsCount;
}
