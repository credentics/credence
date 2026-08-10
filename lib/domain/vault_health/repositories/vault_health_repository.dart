import 'package:pass_doc_manager/domain/vault_health/entities/vault_health_report_entity.dart';

abstract class VaultHealthRepository {
  Future<VaultHealthReportEntity> evaluateVaultHealth();
}
