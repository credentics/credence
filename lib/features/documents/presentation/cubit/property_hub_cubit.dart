import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pass_doc_manager/app/di/injection.dart';
import 'package:pass_doc_manager/domain/documents/usecases/get_property_vaults.dart';
import 'package:pass_doc_manager/features/documents/presentation/cubit/property_hub_state.dart';

class PropertyHubCubit extends Cubit<PropertyHubState> {
  PropertyHubCubit({GetPropertyVaults? getPropertyVaults})
    : _getPropertyVaults = getPropertyVaults ?? getIt(),
      super(const PropertyHubState.initial());

  final GetPropertyVaults _getPropertyVaults;

  Future<void> load() async {
    emit(
      state.copyWith(
        viewStatus: PropertyHubViewStatus.loading,
        clearError: true,
      ),
    );
    try {
      final properties = await _getPropertyVaults(
        const GetPropertyVaultsParams(),
      );
      emit(
        state.copyWith(
          viewStatus: PropertyHubViewStatus.ready,
          properties: properties,
          clearError: true,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          viewStatus: PropertyHubViewStatus.error,
          errorMessage: null,
        ),
      );
    }
  }

  void setFilter(PropertyHubFilter filter) {
    if (filter == state.filter) {
      return;
    }
    emit(state.copyWith(filter: filter));
  }
}
