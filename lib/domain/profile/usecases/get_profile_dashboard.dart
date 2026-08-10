import 'package:pass_doc_manager/core/usecase/usecase.dart';
import 'package:pass_doc_manager/domain/profile/entities/profile_dashboard_entity.dart';
import 'package:pass_doc_manager/domain/profile/repositories/profile_repository.dart';

class GetProfileDashboard
    implements UseCase<ProfileDashboardEntity, GetProfileDashboardParams> {
  GetProfileDashboard(this._repository);

  final ProfileRepository _repository;

  @override
  Future<ProfileDashboardEntity> call(GetProfileDashboardParams params) {
    return _repository.getDashboard();
  }
}

class GetProfileDashboardParams {
  const GetProfileDashboardParams();
}
