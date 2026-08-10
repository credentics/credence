import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pass_doc_manager/app/di/injection.dart';
import 'package:pass_doc_manager/domain/documents/usecases/get_travel_trips.dart';
import 'package:pass_doc_manager/features/documents/presentation/cubit/travel_trips_state.dart';

class TravelTripsCubit extends Cubit<TravelTripsState> {
  TravelTripsCubit({GetTravelTrips? getTravelTrips})
    : _getTravelTrips = getTravelTrips ?? getIt(),
      super(const TravelTripsState.initial());

  final GetTravelTrips _getTravelTrips;

  Future<void> load() async {
    emit(
      state.copyWith(
        viewStatus: TravelTripsViewStatus.loading,
        clearError: true,
      ),
    );
    try {
      final trips = await _getTravelTrips(const GetTravelTripsParams());
      emit(
        state.copyWith(
          viewStatus: TravelTripsViewStatus.ready,
          trips: trips,
          clearError: true,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          viewStatus: TravelTripsViewStatus.error,
          errorMessage: null,
        ),
      );
    }
  }

  void setFilter(TravelTripsFilter filter) {
    if (filter == state.filter) {
      return;
    }
    emit(state.copyWith(filter: filter));
  }
}

