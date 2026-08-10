import 'package:pass_doc_manager/core/usecase/usecase.dart';
import 'package:pass_doc_manager/domain/password_tools/entities/password_generation_policy_entity.dart';
import 'package:pass_doc_manager/domain/password_tools/repositories/password_tools_repository.dart';

class GeneratePassword implements UseCase<String, GeneratePasswordParams> {
  GeneratePassword(this._repository);

  final PasswordToolsRepository _repository;

  @override
  Future<String> call(GeneratePasswordParams params) {
    return _repository.generatePassword(policy: params.policy);
  }
}

class GeneratePasswordParams {
  const GeneratePasswordParams({
    this.policy = const PasswordGenerationPolicyEntity(),
  });

  final PasswordGenerationPolicyEntity policy;
}
