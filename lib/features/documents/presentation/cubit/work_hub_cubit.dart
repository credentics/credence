import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pass_doc_manager/app/di/injection.dart';
import 'package:pass_doc_manager/domain/documents/usecases/get_work_company_vaults.dart';
import 'package:pass_doc_manager/features/documents/presentation/cubit/work_hub_state.dart';

class WorkHubCubit extends Cubit<WorkHubState> {
  WorkHubCubit({GetWorkCompanyVaults? getWorkCompanyVaults})
    : _getWorkCompanyVaults = getWorkCompanyVaults ?? getIt(),
      super(const WorkHubState.initial());

  final GetWorkCompanyVaults _getWorkCompanyVaults;

  Future<void> load() async {
    emit(
      state.copyWith(viewStatus: WorkHubViewStatus.loading, clearError: true),
    );
    try {
      final companies = await _getWorkCompanyVaults(
        const GetWorkCompanyVaultsParams(),
      );
      emit(
        state.copyWith(
          viewStatus: WorkHubViewStatus.ready,
          companies: companies,
          clearError: true,
        ),
      );
    } catch (_) {
      debugPrint('[WorkHub] Failed to load work vaults');
      emit(
        state.copyWith(
          viewStatus: WorkHubViewStatus.error,
          errorMessage: null, // UI uses l10n.documentsErrorWorkVaults
        ),
      );
    }
  }

  void setFilter(WorkHubFilter filter) {
    if (filter == state.filter) {
      return;
    }
    emit(state.copyWith(filter: filter));
  }

  void setQuery(String query) {
    if (query == state.query) {
      return;
    }
    emit(state.copyWith(query: query));
  }
}
