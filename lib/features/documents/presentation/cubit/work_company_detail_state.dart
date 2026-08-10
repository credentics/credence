import 'package:pass_doc_manager/domain/documents/entities/work_company_detail_entity.dart';
import 'package:pass_doc_manager/domain/documents/entities/work_document_folder_type.dart';
import 'package:pass_doc_manager/domain/documents/entities/work_statement_entity.dart';

enum WorkCompanyDetailViewStatus { initial, loading, ready, error }

class WorkCompanyDetailState {
  const WorkCompanyDetailState({
    required this.viewStatus,
    required this.detail,
    required this.selectedYear,
    required this.selectedFolder,
    required this.errorMessage,
  });

  const WorkCompanyDetailState.initial()
    : viewStatus = WorkCompanyDetailViewStatus.initial,
      detail = null,
      selectedYear = null,
      selectedFolder = null,
      errorMessage = null;

  final WorkCompanyDetailViewStatus viewStatus;
  final WorkCompanyDetailEntity? detail;
  final int? selectedYear;
  final WorkDocumentFolderType? selectedFolder;
  final String? errorMessage;

  List<int> get availableYears {
    final source = detail?.statements ?? const <WorkStatementEntity>[];
    final years = <int>{};
    for (final statement in source) {
      final date = statement.statementDate ?? statement.updatedAt;
      years.add(date.year);
    }
    final list = years.toList(growable: false)..sort((a, b) => b.compareTo(a));
    return list;
  }

  List<WorkStatementEntity> get visibleStatements {
    final source = detail?.statements ?? const <WorkStatementEntity>[];
    final filteredByYear = selectedYear == null
        ? source
        : source.where((statement) {
            final date = statement.statementDate ?? statement.updatedAt;
            return date.year == selectedYear;
          });
    final filteredByFolder = selectedFolder == null
        ? filteredByYear
        : filteredByYear.where(
            (statement) => statement.folderType == selectedFolder,
          );
    return filteredByFolder.toList(growable: false);
  }

  WorkCompanyDetailState copyWith({
    WorkCompanyDetailViewStatus? viewStatus,
    WorkCompanyDetailEntity? detail,
    bool clearDetail = false,
    int? selectedYear,
    bool clearSelectedYear = false,
    WorkDocumentFolderType? selectedFolder,
    bool clearSelectedFolder = false,
    String? errorMessage,
    bool clearError = false,
  }) {
    return WorkCompanyDetailState(
      viewStatus: viewStatus ?? this.viewStatus,
      detail: clearDetail ? null : (detail ?? this.detail),
      selectedYear: clearSelectedYear
          ? null
          : (selectedYear ?? this.selectedYear),
      selectedFolder: clearSelectedFolder
          ? null
          : (selectedFolder ?? this.selectedFolder),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}
