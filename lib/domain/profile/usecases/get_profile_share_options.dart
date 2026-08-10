import 'package:pass_doc_manager/core/usecase/usecase.dart';
import 'package:pass_doc_manager/domain/profile/entities/profile_share_options_entity.dart';
import 'package:pass_doc_manager/domain/profile/repositories/profile_repository.dart';

class GetProfileShareOptions
    implements
        UseCase<ProfileShareOptionsEntity, GetProfileShareOptionsParams> {
  GetProfileShareOptions(this._repository);

  final ProfileRepository _repository;

  @override
  Future<ProfileShareOptionsEntity> call(GetProfileShareOptionsParams params) {
    return _repository.getShareOptions();
  }
}

class GetProfileShareOptionsParams {
  const GetProfileShareOptionsParams();
}
