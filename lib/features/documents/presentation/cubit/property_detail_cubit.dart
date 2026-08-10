import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pass_doc_manager/app/di/injection.dart';
import 'package:pass_doc_manager/domain/documents/usecases/get_property_detail.dart';
import 'package:pass_doc_manager/features/documents/presentation/cubit/property_detail_state.dart';

class PropertyDetailCubit extends Cubit<PropertyDetailState> {
  PropertyDetailCubit({GetPropertyDetail? getPropertyDetail})
    : _getPropertyDetail = getPropertyDetail ?? getIt(),
      super(const PropertyDetailState.initial());

  final GetPropertyDetail _getPropertyDetail;

  Future<void> load({required String propertyId}) async {
    emit(
      state.copyWith(
        viewStatus: PropertyDetailViewStatus.loading,
        clearError: true,
      ),
    );
    try {
      final detail = await _getPropertyDetail(
        GetPropertyDetailParams(propertyId: propertyId),
      );
      emit(
        state.copyWith(
          viewStatus: PropertyDetailViewStatus.ready,
          detail: detail,
          clearError: true,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          viewStatus: PropertyDetailViewStatus.error,
          errorMessage: null,
        ),
      );
    }
  }
}
