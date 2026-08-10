import 'package:pass_doc_manager/core/usecase/usecase.dart';
import 'package:pass_doc_manager/domain/documents/entities/travel_trip_entity.dart';
import 'package:pass_doc_manager/domain/documents/repositories/document_repository.dart';

class GetTravelTrips
    implements UseCase<List<TravelTripEntity>, GetTravelTripsParams> {
  GetTravelTrips(this._repository);

  final DocumentRepository _repository;

  @override
  Future<List<TravelTripEntity>> call(GetTravelTripsParams params) {
    return _repository.getTravelTrips();
  }
}

class GetTravelTripsParams {
  const GetTravelTripsParams();
}

