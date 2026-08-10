import 'package:pass_doc_manager/core/usecase/usecase.dart';
import 'package:pass_doc_manager/domain/vault_portability/entities/vault_portability_policy_entity.dart';
import 'package:pass_doc_manager/domain/vault_portability/repositories/vault_portability_repository.dart';

class GetVaultPortabilityPolicy
    implements UseCase<VaultPortabilityPolicyEntity, NoParams> {
  GetVaultPortabilityPolicy(this._repository);

  final VaultPortabilityRepository _repository;

  @override
  Future<VaultPortabilityPolicyEntity> call(NoParams params) {
    return _repository.getPortabilityPolicy();
  }
}

class NoParams {
  const NoParams();
}
