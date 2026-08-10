import 'package:pass_doc_manager/core/usecase/usecase.dart';
import 'package:pass_doc_manager/domain/documents/entities/travel_trip_detail_entity.dart';
import 'package:pass_doc_manager/domain/documents/repositories/document_repository.dart';

class GetTravelTripDetail
    implements UseCase<TravelTripDetailEntity, GetTravelTripDetailParams> {
  GetTravelTripDetail(this._repository);

  final DocumentRepository _repository;

  @override
  Future<TravelTripDetailEntity> call(GetTravelTripDetailParams params) {
    return _repository.getTravelTripDetail(tripId: params.tripId);
  }
}

class GetTravelTripDetailParams {
  const GetTravelTripDetailParams({required this.tripId});

  final String tripId;
}

