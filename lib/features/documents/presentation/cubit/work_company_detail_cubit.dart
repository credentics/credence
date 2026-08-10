import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pass_doc_manager/app/di/injection.dart';
import 'package:pass_doc_manager/domain/documents/entities/work_document_folder_type.dart';
import 'package:pass_doc_manager/domain/documents/usecases/get_work_company_detail.dart';
import 'package:pass_doc_manager/features/documents/presentation/cubit/work_company_detail_state.dart';

class WorkCompanyDetailCubit extends Cubit<WorkCompanyDetailState> {
  WorkCompanyDetailCubit({GetWorkCompanyDetail? getWorkCompanyDetail})
    : _getWorkCompanyDetail = getWorkCompanyDetail ?? getIt(),
      super(const WorkCompanyDetailState.initial());

  final GetWorkCompanyDetail _getWorkCompanyDetail;

  Future<void> load({required String companyId}) async {
    emit(
      state.copyWith(
        viewStatus: WorkCompanyDetailViewStatus.loading,
        clearError: true,
      ),
    );
    try {
      final detail = await _getWorkCompanyDetail(
        GetWorkCompanyDetailParams(companyId: companyId),
      );
      final years = detail.statements
          .map((statement) => (statement.statementDate ?? statement.updatedAt).year)
          .toSet()
          .toList(growable: false)
        ..sort((a, b) => b.compareTo(a));
      emit(
        state.copyWith(
          viewStatus: WorkCompanyDetailViewStatus.ready,
          detail: detail,
          selectedYear: years.isEmpty ? null : years.first,
          clearSelectedFolder: true,
          clearError: true,
        ),
      );
    } catch (_) {
      debugPrint('[WorkCompanyDetail] Failed to load company details');
      emit(
        state.copyWith(
          viewStatus: WorkCompanyDetailViewStatus.error,
          errorMessage: null, // UI uses l10n.documentsErrorCompany
        ),
      );
    }
  }

  void setYear(int? year) {
    if (state.selectedYear == year) {
      return;
    }
    emit(
      state.copyWith(
        selectedYear: year,
        clearSelectedYear: year == null,
      ),
    );
  }

  void setFolder(WorkDocumentFolderType? folder) {
    if (state.selectedFolder == folder) {
      return;
    }
    emit(
      state.copyWith(
        selectedFolder: folder,
        clearSelectedFolder: folder == null,
      ),
    );
  }
}
