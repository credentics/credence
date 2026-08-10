import 'package:pass_doc_manager/domain/password_tools/entities/password_health_issue_entity.dart';

enum PasswordHealthLevel { weak, fair, strong, excellent }

class PasswordHealthReportEntity {
  const PasswordHealthReportEntity({
    required this.score,
    required this.level,
    required this.entropyBits,
    required this.estimatedCrackTime,
    required this.issues,
  });

  final int score;
  final PasswordHealthLevel level;
  final double entropyBits;
  final String estimatedCrackTime;
  final List<PasswordHealthIssueEntity> issues;

  bool get isHealthy =>
      level == PasswordHealthLevel.strong ||
      level == PasswordHealthLevel.excellent;
}
