import 'package:pass_doc_manager/core/usecase/usecase.dart';
import 'package:pass_doc_manager/domain/documents/entities/document_library_overview_entity.dart';
import 'package:pass_doc_manager/domain/documents/repositories/document_repository.dart';

class GetDocumentLibraryOverview
    implements
        UseCase<
          DocumentLibraryOverviewEntity,
          GetDocumentLibraryOverviewParams
        > {
  GetDocumentLibraryOverview(this._repository);

  final DocumentRepository _repository;

  @override
  Future<DocumentLibraryOverviewEntity> call(
    GetDocumentLibraryOverviewParams params,
  ) {
    return _repository.getLibraryOverview();
  }
}

class GetDocumentLibraryOverviewParams {
  const GetDocumentLibraryOverviewParams();
}
