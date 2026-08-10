import 'package:pass_doc_manager/domain/vault_health/entities/vault_health_issue_severity.dart';
import 'package:pass_doc_manager/domain/vault_health/entities/vault_health_issue_type.dart';

class VaultHealthIssueEntity {
  final VaultHealthIssueType type;
  final VaultHealthIssueSeverity severity;
  final String title;
  final String description;
  final String? itemId;
  final String? itemName;

  VaultHealthIssueEntity({
    required this.type,
    required this.severity,
    required this.title,
    required this.description,
    this.itemId,
    this.itemName,
  });
}
