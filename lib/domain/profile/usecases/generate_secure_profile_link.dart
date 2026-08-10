import 'package:pass_doc_manager/core/usecase/usecase.dart';
import 'package:pass_doc_manager/domain/profile/entities/generated_profile_share_link_entity.dart';
import 'package:pass_doc_manager/domain/profile/entities/profile_share_options_entity.dart';
import 'package:pass_doc_manager/domain/profile/repositories/profile_repository.dart';

class GenerateSecureProfileLink
    implements
        UseCase<GeneratedProfileShareLinkEntity, GenerateSecureProfileLinkParams> {
  GenerateSecureProfileLink(this._repository);

  final ProfileRepository _repository;

  @override
  Future<GeneratedProfileShareLinkEntity> call(
    GenerateSecureProfileLinkParams params,
  ) {
    return _repository.generateSecureShareLink(params.options);
  }
}

class GenerateSecureProfileLinkParams {
  const GenerateSecureProfileLinkParams({required this.options});

  final ProfileShareOptionsEntity options;
}
