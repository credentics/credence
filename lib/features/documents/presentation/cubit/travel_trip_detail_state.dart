import 'package:pass_doc_manager/domain/documents/entities/travel_trip_detail_entity.dart';

enum TravelTripDetailViewStatus { initial, loading, ready, error }

class TravelTripDetailState {
  const TravelTripDetailState({
    required this.viewStatus,
    required this.detail,
    required this.errorMessage,
  });

  const TravelTripDetailState.initial()
    : viewStatus = TravelTripDetailViewStatus.initial,
      detail = null,
      errorMessage = null;

  final TravelTripDetailViewStatus viewStatus;
  final TravelTripDetailEntity? detail;
  final String? errorMessage;

  TravelTripDetailState copyWith({
    TravelTripDetailViewStatus? viewStatus,
    TravelTripDetailEntity? detail,
    String? errorMessage,
    bool clearDetail = false,
    bool clearError = false,
  }) {
    return TravelTripDetailState(
      viewStatus: viewStatus ?? this.viewStatus,
      detail: clearDetail ? null : (detail ?? this.detail),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

