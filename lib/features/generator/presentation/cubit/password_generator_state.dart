import 'package:pass_doc_manager/domain/password_tools/entities/generated_password_history_entry_entity.dart';
import 'package:pass_doc_manager/domain/password_tools/entities/password_health_report_entity.dart';

enum PasswordGeneratorViewStatus { initial, loading, generating, ready, error }

class PasswordGeneratorState {
  const PasswordGeneratorState({
    required this.viewStatus,
    required this.length,
    required this.includeUppercase,
    required this.includeLowercase,
    required this.includeNumbers,
    required this.includeSymbols,
    required this.password,
    required this.healthReport,
    required this.history,
    required this.errorMessage,
  });

  const PasswordGeneratorState.initial()
    : viewStatus = PasswordGeneratorViewStatus.initial,
      length = 22,
      includeUppercase = true,
      includeLowercase = true,
      includeNumbers = true,
      includeSymbols = true,
      password = '',
      healthReport = null,
      history = const [],
      errorMessage = null;

  final PasswordGeneratorViewStatus viewStatus;
  final int length;
  final bool includeUppercase;
  final bool includeLowercase;
  final bool includeNumbers;
  final bool includeSymbols;
  final String password;
  final PasswordHealthReportEntity? healthReport;
  final List<GeneratedPasswordHistoryEntryEntity> history;
  final String? errorMessage;

  bool get isBusy =>
      viewStatus == PasswordGeneratorViewStatus.loading ||
      viewStatus == PasswordGeneratorViewStatus.generating;

  PasswordGeneratorState copyWith({
    PasswordGeneratorViewStatus? viewStatus,
    int? length,
    bool? includeUppercase,
    bool? includeLowercase,
    bool? includeNumbers,
    bool? includeSymbols,
    String? password,
    PasswordHealthReportEntity? healthReport,
    List<GeneratedPasswordHistoryEntryEntity>? history,
    String? errorMessage,
  }) {
    return PasswordGeneratorState(
      viewStatus: viewStatus ?? this.viewStatus,
      length: length ?? this.length,
      includeUppercase: includeUppercase ?? this.includeUppercase,
      includeLowercase: includeLowercase ?? this.includeLowercase,
      includeNumbers: includeNumbers ?? this.includeNumbers,
      includeSymbols: includeSymbols ?? this.includeSymbols,
      password: password ?? this.password,
      healthReport: healthReport ?? this.healthReport,
      history: history ?? this.history,
      errorMessage: errorMessage,
    );
  }
}
