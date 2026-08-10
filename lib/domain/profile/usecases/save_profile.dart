import 'package:pass_doc_manager/core/usecase/usecase.dart';
import 'package:pass_doc_manager/domain/profile/entities/profile_entity.dart';
import 'package:pass_doc_manager/domain/profile/repositories/profile_repository.dart';

class SaveProfile implements UseCase<ProfileEntity, SaveProfileParams> {
  SaveProfile(this._repository);

  final ProfileRepository _repository;

  @override
  Future<ProfileEntity> call(SaveProfileParams params) {
    return _repository.saveProfile(params.profile);
  }
}

class SaveProfileParams {
  const SaveProfileParams({required this.profile});

  final ProfileEntity profile;
}
