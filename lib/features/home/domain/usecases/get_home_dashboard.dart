import 'package:pass_doc_manager/core/usecase/usecase.dart';
import 'package:pass_doc_manager/features/home/domain/entities/home_dashboard_entity.dart';
import 'package:pass_doc_manager/features/home/domain/repositories/home_repository.dart';

class GetHomeDashboard implements UseCase<HomeDashboardEntity, GetHomeDashboardParams> {
  GetHomeDashboard(this._repository);
  final HomeRepository _repository;

  @override
  Future<HomeDashboardEntity> call(GetHomeDashboardParams params) {
    return _repository.getDashboard();
  }
}

class GetHomeDashboardParams {
  const GetHomeDashboardParams();
}
