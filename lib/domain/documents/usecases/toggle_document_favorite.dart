import 'package:pass_doc_manager/core/usecase/usecase.dart';
import 'package:pass_doc_manager/domain/documents/repositories/document_repository.dart';

class ToggleDocumentFavorite
    implements UseCase<void, ToggleDocumentFavoriteParams> {
  ToggleDocumentFavorite(this._repository);

  final DocumentRepository _repository;

  @override
  Future<void> call(ToggleDocumentFavoriteParams params) {
    return _repository.toggleFavorite(
      documentId: params.documentId,
      isFavorite: params.isFavorite,
    );
  }
}

class ToggleDocumentFavoriteParams {
  const ToggleDocumentFavoriteParams({
    required this.documentId,
    required this.isFavorite,
  });

  final String documentId;
  final bool isFavorite;
}
