import 'dart:math';

import 'package:pass_doc_manager/domain/password_tools/entities/password_generation_policy_entity.dart';
import 'package:pass_doc_manager/domain/password_tools/entities/password_health_issue_entity.dart';
import 'package:pass_doc_manager/domain/password_tools/entities/password_health_report_entity.dart';

class LocalPasswordToolsService {
  LocalPasswordToolsService() : _random = _buildRandom();

  final Random _random;

  static Random _buildRandom() {
    try {
      return Random.secure();
    } catch (_) {
      return Random();
    }
  }

  Future<String> generatePassword({
    required PasswordGenerationPolicyEntity policy,
  }) async {
    final length = policy.length.clamp(8, 64);
    final lower = policy.excludeAmbiguous
        ? 'abcdefghijkmnopqrstuvwxyz'
        : 'abcdefghijklmnopqrstuvwxyz';
    final upper = policy.excludeAmbiguous
        ? 'ABCDEFGHJKLMNPQRSTUVWXYZ'
        : 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    final numbers = policy.excludeAmbiguous ? '23456789' : '0123456789';
    const symbols = r'!@#$%^&*()-_=+[]{};:,.?';

    final pools = <String>[
      if (policy.includeLowercase) lower,
      if (policy.includeUppercase) upper,
      if (policy.includeNumbers) numbers,
      if (policy.includeSymbols) symbols,
    ];

    if (pools.isEmpty) {
      return '';
    }

    final chars = <String>[];
    for (final pool in pools) {
      chars.add(_pick(pool));
    }

    final fullPool = pools.join();
    while (chars.length < length) {
      chars.add(_pick(fullPool));
    }

    _shuffle(chars);
    return chars.join();
  }

  Future<PasswordHealthReportEntity> evaluatePasswordHealth({
    required String password,
    required String username,
    required String serviceName,
    required List<String> existingPasswords,
  }) async {
    final issues = <PasswordHealthIssueEntity>[];
    var score = 100;
    final trimmed = password.trim();

    if (trimmed.length < 8) {
      issues.add(
        const PasswordHealthIssueEntity(
          code: PasswordHealthIssueCode.tooShort,
          message: 'Password is too short (minimum 8).',
          penalty: 40,
        ),
      );
      score -= 40;
    } else if (trimmed.length < 12) {
      issues.add(
        const PasswordHealthIssueEntity(
          code: PasswordHealthIssueCode.tooShort,
          message: 'Password should be at least 12 characters.',
          penalty: 20,
        ),
      );
      score -= 20;
    }

    final lower = RegExp(r'[a-z]').hasMatch(trimmed);
    final upper = RegExp(r'[A-Z]').hasMatch(trimmed);
    final number = RegExp(r'\d').hasMatch(trimmed);
    final symbol = RegExp(r'[^A-Za-z0-9]').hasMatch(trimmed);
    final charsetCount = [
      lower,
      upper,
      number,
      symbol,
    ].where((it) => it).length;
    if (charsetCount <= 2) {
      issues.add(
        const PasswordHealthIssueEntity(
          code: PasswordHealthIssueCode.lowCharsetDiversity,
          message: 'Use uppercase, lowercase, numbers, and symbols.',
          penalty: 18,
        ),
      );
      score -= 18;
    }

    if (_hasRepeatedPattern(trimmed)) {
      issues.add(
        const PasswordHealthIssueEntity(
          code: PasswordHealthIssueCode.repeatedPattern,
          message: 'Password contains repeated character patterns.',
          penalty: 12,
        ),
      );
      score -= 12;
    }

    if (_hasSequentialPattern(trimmed)) {
      issues.add(
        const PasswordHealthIssueEntity(
          code: PasswordHealthIssueCode.sequentialPattern,
          message: 'Password contains obvious sequences.',
          penalty: 12,
        ),
      );
      score -= 12;
    }

    if (_containsCommonWords(trimmed)) {
      issues.add(
        const PasswordHealthIssueEntity(
          code: PasswordHealthIssueCode.containsCommonWord,
          message: 'Avoid common words and leaked password fragments.',
          penalty: 15,
        ),
      );
      score -= 15;
    }

    if (_isSimilarToAccountData(trimmed, username, serviceName)) {
      issues.add(
        const PasswordHealthIssueEntity(
          code: PasswordHealthIssueCode.similarToAccountData,
          message: 'Avoid using service name or username in password.',
          penalty: 16,
        ),
      );
      score -= 16;
    }

    if (_isReused(trimmed, existingPasswords)) {
      issues.add(
        const PasswordHealthIssueEntity(
          code: PasswordHealthIssueCode.reusedPassword,
          message: 'Password is reused in another account.',
          penalty: 35,
        ),
      );
      score -= 35;
    }

    final entropyBits = _estimateEntropyBits(trimmed);
    final scoreFromEntropy = (entropyBits * 1.25).round().clamp(0, 100);
    score = ((score + scoreFromEntropy) / 2).round().clamp(0, 100);
    final level = _mapLevel(score);

    return PasswordHealthReportEntity(
      score: score,
      level: level,
      entropyBits: entropyBits,
      estimatedCrackTime: _estimateCrackTime(entropyBits),
      issues: issues,
    );
  }

  bool _hasRepeatedPattern(String value) {
    if (value.length < 4) {
      return false;
    }
    return RegExp(r'(.)\1{2,}').hasMatch(value);
  }

  bool _hasSequentialPattern(String value) {
    if (value.length < 3) {
      return false;
    }

    final lower = value.toLowerCase();
    for (var i = 0; i <= lower.length - 3; i += 1) {
      final a = lower.codeUnitAt(i);
      final b = lower.codeUnitAt(i + 1);
      final c = lower.codeUnitAt(i + 2);
      if ((b - a == 1 && c - b == 1) || (a - b == 1 && b - c == 1)) {
        return true;
      }
    }
    return false;
  }

  bool _containsCommonWords(String value) {
    final normalized = value.toLowerCase();
    const common = [
      'password',
      'qwerty',
      'admin',
      'welcome',
      'letmein',
      '123456',
      'passw0rd',
    ];
    return common.any(normalized.contains);
  }

  bool _isSimilarToAccountData(String value, String username, String service) {
    final password = value.toLowerCase();
    final normalizedUsername = username.toLowerCase().trim();
    final normalizedService = service.toLowerCase().trim();

    final usernameTokens = normalizedUsername
        .split(RegExp(r'[^a-z0-9]+'))
        .where((it) => it.length >= 3);
    final serviceTokens = normalizedService
        .split(RegExp(r'[^a-z0-9]+'))
        .where((it) => it.length >= 3);

    return [...usernameTokens, ...serviceTokens].any(password.contains);
  }

  bool _isReused(String value, List<String> existingPasswords) {
    final normalized = value.trim();
    return existingPasswords.any((it) => it.trim() == normalized);
  }

  double _estimateEntropyBits(String value) {
    if (value.isEmpty) {
      return 0;
    }

    var pool = 0;
    if (RegExp(r'[a-z]').hasMatch(value)) {
      pool += 26;
    }
    if (RegExp(r'[A-Z]').hasMatch(value)) {
      pool += 26;
    }
    if (RegExp(r'\d').hasMatch(value)) {
      pool += 10;
    }
    if (RegExp(r'[^A-Za-z0-9]').hasMatch(value)) {
      pool += 32;
    }
    if (pool == 0) {
      return 0;
    }
    return value.length * (log(pool) / ln2);
  }

  PasswordHealthLevel _mapLevel(int score) {
    if (score >= 85) {
      return PasswordHealthLevel.excellent;
    }
    if (score >= 70) {
      return PasswordHealthLevel.strong;
    }
    if (score >= 50) {
      return PasswordHealthLevel.fair;
    }
    return PasswordHealthLevel.weak;
  }

  String _estimateCrackTime(double entropyBits) {
    if (entropyBits <= 0) {
      return 'Instant';
    }

    const guessesPerSecond = 1e10;
    final seconds = pow(2, entropyBits) / guessesPerSecond;

    if (seconds < 60) {
      return 'Less than a minute';
    }
    if (seconds < 3600) {
      return '${(seconds / 60).round()} minutes';
    }
    if (seconds < 86400) {
      return '${(seconds / 3600).round()} hours';
    }
    if (seconds < 31557600) {
      return '${(seconds / 86400).round()} days';
    }
    final years = (seconds / 31557600).round();
    if (years > 1000000) {
      return 'Millions of years';
    }
    return '$years years';
  }

  String _pick(String pool) => pool[_random.nextInt(pool.length)];

  void _shuffle(List<String> chars) {
    for (var i = chars.length - 1; i > 0; i -= 1) {
      final j = _random.nextInt(i + 1);
      final temp = chars[i];
      chars[i] = chars[j];
      chars[j] = temp;
    }
  }
}
