import 'package:pass_doc_manager/domain/documents/entities/document_expiry_item_entity.dart';
import 'package:pass_doc_manager/features/documents/presentation/cubit/document_timeline_cubit.dart';

enum DocumentTimelineStatus { initial, loading, loaded, error }

class DocumentTimelineState {
  const DocumentTimelineState({
    required this.status,
    required this.documents,
    required this.selectedFilter,
    required this.errorMessage,
  });

  const DocumentTimelineState.initial()
    : status = DocumentTimelineStatus.initial,
      documents = const [],
      selectedFilter = ExpiryFilter.all,
      errorMessage = null;

  final DocumentTimelineStatus status;
  final List<DocumentExpiryItemEntity> documents;
  final ExpiryFilter selectedFilter;
  final String? errorMessage;

  List<DocumentExpiryItemEntity> get filteredDocuments {
    switch (selectedFilter) {
      case ExpiryFilter.all:
        return documents;
      case ExpiryFilter.expired:
        return documents
            .where((d) => d.urgency == ExpiryUrgency.expired)
            .toList();
      case ExpiryFilter.critical:
        return documents
            .where((d) =>
                d.urgency == ExpiryUrgency.expired ||
                d.urgency == ExpiryUrgency.critical)
            .toList();
      case ExpiryFilter.warning:
        return documents
            .where((d) =>
                d.urgency == ExpiryUrgency.expired ||
                d.urgency == ExpiryUrgency.critical ||
                d.urgency == ExpiryUrgency.warning)
            .toList();
      case ExpiryFilter.safe:
        return documents
            .where((d) => d.urgency == ExpiryUrgency.safe)
            .toList();
    }
  }

  int get expiredCount =>
      documents
          .where((d) => d.urgency == ExpiryUrgency.expired)
          .length;

  int get criticalCount =>
      documents
          .where((d) => d.urgency == ExpiryUrgency.critical)
          .length;

  int get warningCount =>
      documents
          .where((d) => d.urgency == ExpiryUrgency.warning)
          .length;

  int get safeCount =>
      documents
          .where((d) => d.urgency == ExpiryUrgency.safe)
          .length;

  DocumentTimelineState copyWith({
    DocumentTimelineStatus? status,
    List<DocumentExpiryItemEntity>? documents,
    ExpiryFilter? selectedFilter,
    String? errorMessage,
    bool clearError = false,
  }) {
    return DocumentTimelineState(
      status: status ?? this.status,
      documents: documents ?? this.documents,
      selectedFilter: selectedFilter ?? this.selectedFilter,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}
