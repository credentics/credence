import 'package:pass_doc_manager/core/usecase/usecase.dart';
import 'package:pass_doc_manager/domain/profile/entities/profile_share_options_entity.dart';
import 'package:pass_doc_manager/domain/profile/repositories/profile_repository.dart';

class SaveProfileShareOptions
    implements
        UseCase<ProfileShareOptionsEntity, SaveProfileShareOptionsParams> {
  SaveProfileShareOptions(this._repository);

  final ProfileRepository _repository;

  @override
  Future<ProfileShareOptionsEntity> call(SaveProfileShareOptionsParams params) {
    return _repository.saveShareOptions(params.options);
  }
}

class SaveProfileShareOptionsParams {
  const SaveProfileShareOptionsParams({required this.options});

  final ProfileShareOptionsEntity options;
}
