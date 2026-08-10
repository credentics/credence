import 'package:flutter_test/flutter_test.dart';
import 'package:pass_doc_manager/data/password_tools/repositories/password_tools_repository_impl.dart';
import 'package:pass_doc_manager/data/password_tools/services/local_password_tools_service.dart';
import 'package:pass_doc_manager/domain/password_tools/entities/password_generation_policy_entity.dart';
import 'package:pass_doc_manager/domain/password_tools/entities/password_health_issue_entity.dart';
import 'package:pass_doc_manager/domain/password_tools/entities/password_health_report_entity.dart';
import 'package:pass_doc_manager/domain/password_tools/usecases/evaluate_password_health.dart';
import 'package:pass_doc_manager/domain/password_tools/usecases/generate_password.dart';

void main() {
  group('Password tools use cases', () {
    late GeneratePassword generatePassword;
    late EvaluatePasswordHealth evaluatePasswordHealth;

    setUp(() {
      final repository = PasswordToolsRepositoryImpl(
        localService: LocalPasswordToolsService(),
      );
      generatePassword = GeneratePassword(repository);
      evaluatePasswordHealth = EvaluatePasswordHealth(repository);
    });

    test('generates password matching requested policy', () async {
      final generated = await generatePassword(
        const GeneratePasswordParams(
          policy: PasswordGenerationPolicyEntity(
            length: 24,
            includeLowercase: true,
            includeUppercase: true,
            includeNumbers: true,
            includeSymbols: true,
          ),
        ),
      );

      expect(generated.length, 24);
      expect(RegExp(r'[a-z]').hasMatch(generated), isTrue);
      expect(RegExp(r'[A-Z]').hasMatch(generated), isTrue);
      expect(RegExp(r'\d').hasMatch(generated), isTrue);
      expect(RegExp(r'[^A-Za-z0-9]').hasMatch(generated), isTrue);
    });

    test('returns weak health report for obvious password', () async {
      final report = await evaluatePasswordHealth(
        const EvaluatePasswordHealthParams(
          password: 'password123',
          username: 'john.smith',
          serviceName: 'GitHub',
        ),
      );

      expect(
        report.level == PasswordHealthLevel.weak ||
            report.level == PasswordHealthLevel.fair,
        isTrue,
      );
      expect(report.score, lessThan(60));
      expect(
        report.issues.any(
          (it) => it.code == PasswordHealthIssueCode.containsCommonWord,
        ),
        isTrue,
      );
    });

    test('marks reused passwords as risky', () async {
      final report = await evaluatePasswordHealth(
        const EvaluatePasswordHealthParams(
          password: 'Strong!Pass#2026',
          existingPasswords: ['Strong!Pass#2026'],
        ),
      );

      expect(
        report.issues.any(
          (it) => it.code == PasswordHealthIssueCode.reusedPassword,
        ),
        isTrue,
      );
    });
  });
}
