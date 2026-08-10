import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pass_doc_manager/app/di/injection.dart';
import 'package:pass_doc_manager/domain/password_tools/entities/password_generation_policy_entity.dart';
import 'package:pass_doc_manager/domain/password_tools/usecases/evaluate_password_health.dart';
import 'package:pass_doc_manager/domain/password_tools/usecases/get_generated_password_history.dart';
import 'package:pass_doc_manager/domain/password_tools/usecases/generate_password.dart';
import 'package:pass_doc_manager/domain/password_tools/usecases/save_generated_password_history_entry.dart';
import 'package:pass_doc_manager/domain/password_tools/usecases/clear_generated_password_history.dart';
import 'package:pass_doc_manager/features/generator/presentation/cubit/password_generator_state.dart';

class PasswordGeneratorCubit extends Cubit<PasswordGeneratorState> {
  PasswordGeneratorCubit({
    GeneratePassword? generatePassword,
    EvaluatePasswordHealth? evaluatePasswordHealth,
    GetGeneratedPasswordHistory? getGeneratedPasswordHistory,
    SaveGeneratedPasswordHistoryEntry? saveGeneratedPasswordHistoryEntry,
    ClearGeneratedPasswordHistory? clearGeneratedPasswordHistory,
  }) : _generatePassword = generatePassword ?? getIt(),
       _evaluatePasswordHealth = evaluatePasswordHealth ?? getIt(),
       _getGeneratedPasswordHistory = getGeneratedPasswordHistory ?? getIt(),
       _saveGeneratedPasswordHistoryEntry =
           saveGeneratedPasswordHistoryEntry ?? getIt(),
       _clearGeneratedPasswordHistory =
           clearGeneratedPasswordHistory ?? getIt(),
       super(const PasswordGeneratorState.initial());

  final GeneratePassword _generatePassword;
  final EvaluatePasswordHealth _evaluatePasswordHealth;
  final GetGeneratedPasswordHistory _getGeneratedPasswordHistory;
  final SaveGeneratedPasswordHistoryEntry _saveGeneratedPasswordHistoryEntry;
  final ClearGeneratedPasswordHistory _clearGeneratedPasswordHistory;

  Future<void> load() async {
    await _loadHistory();
    emit(state.copyWith(viewStatus: PasswordGeneratorViewStatus.loading));
    await regenerate();
  }

  Future<void> regenerate() async {
    emit(state.copyWith(viewStatus: PasswordGeneratorViewStatus.generating));
    try {
      final generated = await _generatePassword(
        GeneratePasswordParams(policy: _policyFromState(state)),
      );
      final report = await _evaluatePasswordHealth(
        EvaluatePasswordHealthParams(
          password: generated,
          username: '',
          serviceName: '',
          existingPasswords: const [],
        ),
      );

      emit(
        state.copyWith(
          viewStatus: PasswordGeneratorViewStatus.ready,
          password: generated,
          healthReport: report,
          errorMessage: null,
        ),
      );
    } catch (_) {
      debugPrint('[PasswordGenerator] Failed to generate password');
      emit(
        state.copyWith(
          viewStatus: PasswordGeneratorViewStatus.error,
          errorMessage: null, // UI uses l10n.generatorErrorGenerate
        ),
      );
    }
  }

  Future<void> saveCopiedPassword({String? password}) async {
    final currentPassword = (password ?? state.password).trim();
    if (currentPassword.isEmpty) {
      return;
    }

    try {
      await _saveGeneratedPasswordHistoryEntry(
        SaveGeneratedPasswordHistoryEntryParams(
          password: currentPassword,
          length: currentPassword.length,
          score: state.healthReport?.score,
        ),
      );
      await _loadHistory();
      emit(state.copyWith(errorMessage: null));
    } catch (e) {
      debugPrint('[PasswordGenerator] Failed to save history entry: $e');
    }
  }

  Future<void> setLength(int length) async {
    final next = length.clamp(8, 40);
    emit(state.copyWith(length: next));
    await regenerate();
  }

  Future<void> toggleUppercase(bool value) async {
    await _toggleRule(
      includeUppercase: value,
      includeLowercase: state.includeLowercase,
      includeNumbers: state.includeNumbers,
      includeSymbols: state.includeSymbols,
    );
  }

  Future<void> toggleLowercase(bool value) async {
    await _toggleRule(
      includeUppercase: state.includeUppercase,
      includeLowercase: value,
      includeNumbers: state.includeNumbers,
      includeSymbols: state.includeSymbols,
    );
  }

  Future<void> toggleNumbers(bool value) async {
    await _toggleRule(
      includeUppercase: state.includeUppercase,
      includeLowercase: state.includeLowercase,
      includeNumbers: value,
      includeSymbols: state.includeSymbols,
    );
  }

  Future<void> toggleSymbols(bool value) async {
    await _toggleRule(
      includeUppercase: state.includeUppercase,
      includeLowercase: state.includeLowercase,
      includeNumbers: state.includeNumbers,
      includeSymbols: value,
    );
  }

  Future<void> _toggleRule({
    required bool includeUppercase,
    required bool includeLowercase,
    required bool includeNumbers,
    required bool includeSymbols,
  }) async {
    final enabledCount = [
      includeUppercase,
      includeLowercase,
      includeNumbers,
      includeSymbols,
    ].where((it) => it).length;
    if (enabledCount == 0) {
      return;
    }

    emit(
      state.copyWith(
        includeUppercase: includeUppercase,
        includeLowercase: includeLowercase,
        includeNumbers: includeNumbers,
        includeSymbols: includeSymbols,
      ),
    );
    await regenerate();
  }

  Future<void> clearHistory() async {
    try {
      await _clearGeneratedPasswordHistory(
        const ClearGeneratedPasswordHistoryParams(),
      );
      emit(state.copyWith(history: const [], errorMessage: null));
    } catch (e) {
      debugPrint('[PasswordGenerator] Failed to clear history: $e');
    }
  }

  Future<void> useHistoryPassword(String password) async {
    final trimmed = password.trim();
    if (trimmed.isEmpty) {
      return;
    }

    try {
      final report = await _evaluatePasswordHealth(
        EvaluatePasswordHealthParams(
          password: trimmed,
          username: '',
          serviceName: '',
          existingPasswords: const [],
        ),
      );

      emit(
        state.copyWith(
          viewStatus: PasswordGeneratorViewStatus.ready,
          password: trimmed,
          healthReport: report,
          errorMessage: null,
        ),
      );
    } catch (e) {
      debugPrint('[PasswordGenerator] Failed to evaluate password health: $e');
    }
  }

  Future<void> _loadHistory() async {
    try {
      final history = await _getGeneratedPasswordHistory(
        const GetGeneratedPasswordHistoryParams(),
      );
      emit(state.copyWith(history: history));
    } catch (e) {
      debugPrint('[PasswordGenerator] Failed to load history: $e');
    }
  }

  PasswordGenerationPolicyEntity _policyFromState(PasswordGeneratorState s) {
    return PasswordGenerationPolicyEntity(
      length: s.length,
      includeLowercase: s.includeLowercase,
      includeUppercase: s.includeUppercase,
      includeNumbers: s.includeNumbers,
      includeSymbols: s.includeSymbols,
      excludeAmbiguous: true,
    );
  }
}
