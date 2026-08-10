import 'package:pass_doc_manager/domain/documents/entities/travel_trip_entity.dart';

enum TravelTripsViewStatus { initial, loading, ready, error }

enum TravelTripsFilter { upcoming, past }

class TravelTripsState {
  const TravelTripsState({
    required this.viewStatus,
    required this.trips,
    required this.filter,
    required this.errorMessage,
  });

  const TravelTripsState.initial()
    : viewStatus = TravelTripsViewStatus.initial,
      trips = const <TravelTripEntity>[],
      filter = TravelTripsFilter.upcoming,
      errorMessage = null;

  final TravelTripsViewStatus viewStatus;
  final List<TravelTripEntity> trips;
  final TravelTripsFilter filter;
  final String? errorMessage;

  List<TravelTripEntity> get visibleTrips {
    final today = DateTime.now();
    return trips.where((trip) {
      final isPast = trip.endDate.isBefore(
        DateTime(today.year, today.month, today.day),
      );
      if (filter == TravelTripsFilter.past) {
        return isPast;
      }
      return !isPast;
    }).toList(growable: false);
  }

  TravelTripsState copyWith({
    TravelTripsViewStatus? viewStatus,
    List<TravelTripEntity>? trips,
    TravelTripsFilter? filter,
    String? errorMessage,
    bool clearError = false,
  }) {
    return TravelTripsState(
      viewStatus: viewStatus ?? this.viewStatus,
      trips: trips ?? this.trips,
      filter: filter ?? this.filter,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

