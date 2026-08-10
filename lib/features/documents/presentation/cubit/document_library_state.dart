import 'package:pass_doc_manager/domain/documents/entities/document_library_overview_entity.dart';
import 'package:pass_doc_manager/domain/documents/entities/document_expiry_item_entity.dart';

enum DocumentLibraryViewStatus { initial, loading, ready, error }

class DocumentLibraryState {
  const DocumentLibraryState({
    required this.viewStatus,
    required this.overview,
    required this.expiringDocuments,
    required this.errorMessage,
  });

  const DocumentLibraryState.initial()
    : viewStatus = DocumentLibraryViewStatus.initial,
      overview = null,
      expiringDocuments = const [],
      errorMessage = null;

  final DocumentLibraryViewStatus viewStatus;
  final DocumentLibraryOverviewEntity? overview;
  final List<DocumentExpiryItemEntity> expiringDocuments;
  final String? errorMessage;

  DocumentLibraryState copyWith({
    DocumentLibraryViewStatus? viewStatus,
    DocumentLibraryOverviewEntity? overview,
    List<DocumentExpiryItemEntity>? expiringDocuments,
    bool clearOverview = false,
    String? errorMessage,
    bool clearError = false,
  }) {
    return DocumentLibraryState(
      viewStatus: viewStatus ?? this.viewStatus,
      overview: clearOverview ? null : (overview ?? this.overview),
      expiringDocuments: expiringDocuments ?? this.expiringDocuments,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}
