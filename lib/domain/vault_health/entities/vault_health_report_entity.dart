import 'package:pass_doc_manager/domain/vault_health/entities/vault_health_grade.dart';
import 'package:pass_doc_manager/domain/vault_health/entities/vault_health_issue_entity.dart';

class VaultHealthReportEntity {
  final int overallScore;
  final VaultHealthGrade grade;
  final List<VaultHealthIssueEntity> issues;
  final int totalCredentials;
  final int weakPasswordCount;
  final int reusedPasswordCount;
  final int noMfaCount;
  final int breachedCount;
  final int expiringDocuments30;
  final int expiringDocuments60;
  final int expiringDocuments90;
  final int expiredDocuments;
  final DateTime checkedAt;

  VaultHealthReportEntity({
    required this.overallScore,
    required this.grade,
    required this.issues,
    required this.totalCredentials,
    required this.weakPasswordCount,
    required this.reusedPasswordCount,
    required this.noMfaCount,
    required this.breachedCount,
    required this.expiringDocuments30,
    required this.expiringDocuments60,
    required this.expiringDocuments90,
    required this.expiredDocuments,
    required this.checkedAt,
  });
}
