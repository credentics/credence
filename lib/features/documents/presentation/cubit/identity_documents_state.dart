import 'package:pass_doc_manager/domain/documents/entities/identity_document_entity.dart';
import 'package:pass_doc_manager/domain/documents/entities/identity_document_group.dart';

enum IdentityDocumentsViewStatus { initial, loading, ready, error }

enum IdentityDocumentsFilter { all, personal, travel }

class IdentityDocumentsState {
  const IdentityDocumentsState({
    required this.viewStatus,
    required this.items,
    required this.filter,
    required this.errorMessage,
  });

  const IdentityDocumentsState.initial()
    : viewStatus = IdentityDocumentsViewStatus.initial,
      items = const [],
      filter = IdentityDocumentsFilter.all,
      errorMessage = null;

  final IdentityDocumentsViewStatus viewStatus;
  final List<IdentityDocumentEntity> items;
  final IdentityDocumentsFilter filter;
  final String? errorMessage;

  List<IdentityDocumentEntity> get filteredItems {
    return switch (filter) {
      IdentityDocumentsFilter.all => items,
      IdentityDocumentsFilter.personal =>
        items
            .where((item) => item.group == IdentityDocumentGroup.personal)
            .toList(growable: false),
      IdentityDocumentsFilter.travel =>
        items
            .where((item) => item.group == IdentityDocumentGroup.travel)
            .toList(growable: false),
    };
  }

  IdentityDocumentsState copyWith({
    IdentityDocumentsViewStatus? viewStatus,
    List<IdentityDocumentEntity>? items,
    IdentityDocumentsFilter? filter,
    String? errorMessage,
    bool clearError = false,
  }) {
    return IdentityDocumentsState(
      viewStatus: viewStatus ?? this.viewStatus,
      items: items ?? this.items,
      filter: filter ?? this.filter,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}
