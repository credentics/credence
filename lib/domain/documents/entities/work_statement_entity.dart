import 'package:pass_doc_manager/domain/documents/entities/work_document_folder_type.dart';

class WorkStatementEntity {
  const WorkStatementEntity({
    required this.documentId,
    required this.title,
    required this.folderType,
    required this.updatedAt,
    required this.statementDate,
    required this.netAmountLabel,
    required this.statusLabel,
    required this.isArchived,
    this.filesCount = 1,
    this.label = '',
  });

  final String documentId;
  final String title;
  final WorkDocumentFolderType folderType;
  final DateTime updatedAt;
  final DateTime? statementDate;
  final String netAmountLabel;
  final String statusLabel;
  final bool isArchived;
  final int filesCount;
  final String label;
}
