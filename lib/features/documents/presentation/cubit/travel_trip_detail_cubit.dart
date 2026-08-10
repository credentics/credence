import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pass_doc_manager/app/di/injection.dart';
import 'package:pass_doc_manager/domain/documents/usecases/get_travel_trip_detail.dart';
import 'package:pass_doc_manager/features/documents/presentation/cubit/travel_trip_detail_state.dart';

class TravelTripDetailCubit extends Cubit<TravelTripDetailState> {
  TravelTripDetailCubit({GetTravelTripDetail? getTravelTripDetail})
    : _getTravelTripDetail = getTravelTripDetail ?? getIt(),
      super(const TravelTripDetailState.initial());

  final GetTravelTripDetail _getTravelTripDetail;

  Future<void> load({required String tripId}) async {
    emit(
      state.copyWith(
        viewStatus: TravelTripDetailViewStatus.loading,
        clearError: true,
      ),
    );
    try {
      final detail = await _getTravelTripDetail(
        GetTravelTripDetailParams(tripId: tripId),
      );
      emit(
        state.copyWith(
          viewStatus: TravelTripDetailViewStatus.ready,
          detail: detail,
          clearError: true,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          viewStatus: TravelTripDetailViewStatus.error,
          errorMessage: null,
        ),
      );
    }
  }
}

