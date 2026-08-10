import 'package:pass_doc_manager/domain/documents/entities/work_document_folder_type.dart';

class WorkCompanyFolderSummaryEntity {
  const WorkCompanyFolderSummaryEntity({
    required this.folderType,
    required this.documentsCount,
  });

  final WorkDocumentFolderType folderType;
  final int documentsCount;
}
