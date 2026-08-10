import 'package:pass_doc_manager/domain/vault_health/entities/vault_health_report_entity.dart';
import 'package:pass_doc_manager/domain/vault_health/repositories/vault_health_repository.dart';

class EvaluateVaultHealth {
  EvaluateVaultHealth({required VaultHealthRepository repository})
      : _repository = repository;

  final VaultHealthRepository _repository;

  Future<VaultHealthReportEntity> call() async {
    return _repository.evaluateVaultHealth();
  }
}
