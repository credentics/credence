import 'package:pass_doc_manager/domain/vault_health/entities/vault_health_report_entity.dart';

enum VaultHealthStatus { initial, loading, ready, error }

class VaultHealthState {
  const VaultHealthState({
    this.status = VaultHealthStatus.initial,
    this.healthReport,
    this.errorMessage,
  });

  const VaultHealthState.initial() : this();

  final VaultHealthStatus status;
  final VaultHealthReportEntity? healthReport;
  final String? errorMessage;

  VaultHealthState copyWith({
    VaultHealthStatus? status,
    VaultHealthReportEntity? healthReport,
    String? errorMessage,
  }) =>
      VaultHealthState(
        status: status ?? this.status,
        healthReport: healthReport ?? this.healthReport,
        errorMessage: errorMessage ?? this.errorMessage,
      );
}
