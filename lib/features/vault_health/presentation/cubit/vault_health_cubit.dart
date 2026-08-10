import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pass_doc_manager/domain/vault_health/usecases/evaluate_vault_health.dart';
import 'package:pass_doc_manager/features/vault_health/presentation/cubit/vault_health_state.dart';

class VaultHealthCubit extends Cubit<VaultHealthState> {
  VaultHealthCubit({required EvaluateVaultHealth evaluateVaultHealth})
      : _evaluateVaultHealth = evaluateVaultHealth,
        super(const VaultHealthState.initial());

  final EvaluateVaultHealth _evaluateVaultHealth;

  Future<void> evaluateHealth() async {
    emit(state.copyWith(status: VaultHealthStatus.loading));
    try {
      final report = await _evaluateVaultHealth();
      emit(state.copyWith(
        status: VaultHealthStatus.ready,
        healthReport: report,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: VaultHealthStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> refresh() async {
    await evaluateHealth();
  }
}
