import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:pass_doc_manager/data/password_tools/services/local_password_tools_service.dart';
import 'package:pass_doc_manager/domain/password_tools/entities/password_generation_policy_entity.dart';
import 'package:pass_doc_manager/domain/password_tools/entities/password_health_issue_entity.dart';
import 'package:pass_doc_manager/domain/password_tools/entities/password_health_report_entity.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late LocalPasswordToolsService service;

  setUp(() {
    service = LocalPasswordToolsService();
  });

  // ── Health evaluation ──

  group('Password health evaluation', () {
    test('short password (< 8 chars) scores weak', () async {
      final report = await service.evaluatePasswordHealth(
        password: 'Ab1!',
        username: '',
        serviceName: '',
        existingPasswords: [],
      );

      expect(report.level, PasswordHealthLevel.weak);
      expect(
        report.issues.any((i) => i.code == PasswordHealthIssueCode.tooShort),
        isTrue,
      );
    });

    test('long password with all charsets scores excellent', () async {
      final report = await service.evaluatePasswordHealth(
        password: r'Xk9#mLp2$vQw7!rT@nBz',
        username: '',
        serviceName: '',
        existingPasswords: [],
      );

      expect(report.score, greaterThanOrEqualTo(85));
      expect(report.level, PasswordHealthLevel.excellent);
    });

    test('password matching username penalizes score', () async {
      final report = await service.evaluatePasswordHealth(
        password: 'john_smith_secure99!',
        username: 'john.smith',
        serviceName: '',
        existingPasswords: [],
      );

      expect(
        report.issues.any(
          (i) => i.code == PasswordHealthIssueCode.similarToAccountData,
        ),
        isTrue,
      );
    });

    test('password matching service name penalizes score', () async {
      final report = await service.evaluatePasswordHealth(
        password: 'MyGithubPass123!',
        username: '',
        serviceName: 'GitHub',
        existingPasswords: [],
      );

      expect(
        report.issues.any(
          (i) => i.code == PasswordHealthIssueCode.similarToAccountData,
        ),
        isTrue,
      );
    });

    test('reused password (exists in existingPasswords) penalizes heavily',
        () async {
      final report = await service.evaluatePasswordHealth(
        password: 'UniquePass!2026',
        username: '',
        serviceName: '',
        existingPasswords: ['UniquePass!2026', 'OtherPass!'],
      );

      expect(
        report.issues.any(
          (i) => i.code == PasswordHealthIssueCode.reusedPassword,
        ),
        isTrue,
      );
      // Reuse penalty is 35 points, so score should be noticeably lower.
      final cleanReport = await service.evaluatePasswordHealth(
        password: 'UniquePass!2026',
        username: '',
        serviceName: '',
        existingPasswords: [],
      );
      expect(report.score, lessThan(cleanReport.score));
    });

    test('sequential characters (abc, 123) reduce score', () async {
      final report = await service.evaluatePasswordHealth(
        password: 'abc12345XYZ!',
        username: '',
        serviceName: '',
        existingPasswords: [],
      );

      expect(
        report.issues.any(
          (i) => i.code == PasswordHealthIssueCode.sequentialPattern,
        ),
        isTrue,
      );
    });

    test('repeated characters (aaa, 111) reduce score', () async {
      final report = await service.evaluatePasswordHealth(
        password: 'Paaa111!!word',
        username: '',
        serviceName: '',
        existingPasswords: [],
      );

      expect(
        report.issues.any(
          (i) => i.code == PasswordHealthIssueCode.repeatedPattern,
        ),
        isTrue,
      );
    });

    test('entropy calculation correct for known inputs', () async {
      // A 10-char lowercase-only password: pool = 26, entropy = 10 * log2(26)
      final report = await service.evaluatePasswordHealth(
        password: 'abcdefghij',
        username: '',
        serviceName: '',
        existingPasswords: [],
      );

      final expectedEntropy = 10 * (log(26) / ln2);
      expect(report.entropyBits, closeTo(expectedEntropy, 0.01));
    });
  });

  // ── Password generation ──

  group('Password generation', () {
    test('generated password respects policy length', () async {
      final password = await service.generatePassword(
        policy: const PasswordGenerationPolicyEntity(length: 32),
      );

      expect(password.length, 32);
    });

    test('generated password without symbols has no symbols', () async {
      final password = await service.generatePassword(
        policy: const PasswordGenerationPolicyEntity(
          length: 20,
          includeSymbols: false,
          includeLowercase: true,
          includeUppercase: true,
          includeNumbers: true,
        ),
      );

      expect(password.length, 20);
      expect(RegExp(r'[!@#$%^&*()\-_=+\[\]{};:,.?]').hasMatch(password), isFalse);
    });

    test('generated password without uppercase has no uppercase', () async {
      final password = await service.generatePassword(
        policy: const PasswordGenerationPolicyEntity(
          length: 20,
          includeUppercase: false,
          includeLowercase: true,
          includeNumbers: true,
          includeSymbols: true,
        ),
      );

      expect(password.length, 20);
      expect(RegExp(r'[A-Z]').hasMatch(password), isFalse);
    });
  });
}
