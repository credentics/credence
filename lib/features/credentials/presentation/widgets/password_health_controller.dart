import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:pass_doc_manager/domain/password_tools/entities/password_health_report_entity.dart';
import 'package:pass_doc_manager/domain/password_tools/usecases/evaluate_password_health.dart';

class PasswordHealthController extends ChangeNotifier {
  PasswordHealthController({
    required EvaluatePasswordHealth evaluatePasswordHealth,
    this.debounce = const Duration(milliseconds: 220),
  }) : _evaluatePasswordHealth = evaluatePasswordHealth;

  final EvaluatePasswordHealth _evaluatePasswordHealth;
  final Duration debounce;

  Timer? _debounceTimer;
  int _evaluationToken = 0;
  bool _isEvaluating = false;
  PasswordHealthReportEntity? _report;

  bool get isEvaluating => _isEvaluating;
  PasswordHealthReportEntity? get report => _report;

  void refresh({
    required String password,
    required String username,
    required String serviceName,
    List<String> existingPasswords = const [],
    bool immediate = false,
  }) {
    _debounceTimer?.cancel();

    Future<void> evaluate() async {
      final trimmedPassword = password.trim();
      if (trimmedPassword.isEmpty) {
        _isEvaluating = false;
        _report = null;
        notifyListeners();
        return;
      }

      final token = ++_evaluationToken;
      _isEvaluating = true;
      notifyListeners();

      try {
        final next = await _evaluatePasswordHealth(
          EvaluatePasswordHealthParams(
            password: password,
            username: username,
            serviceName: serviceName,
            existingPasswords: existingPasswords,
          ),
        );
        if (token != _evaluationToken) {
          return;
        }

        _report = next;
        _isEvaluating = false;
        notifyListeners();
      } catch (_) {
        if (token != _evaluationToken) {
          return;
        }

        _isEvaluating = false;
        notifyListeners();
      }
    }

    if (immediate) {
      unawaited(evaluate());
      return;
    }

    _debounceTimer = Timer(debounce, () => unawaited(evaluate()));
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }
}
