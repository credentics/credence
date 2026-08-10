import 'package:pass_doc_manager/domain/documents/entities/work_company_folder_summary_entity.dart';
import 'package:pass_doc_manager/domain/documents/entities/work_company_recent_activity_entity.dart';
import 'package:pass_doc_manager/domain/documents/entities/work_statement_entity.dart';

class WorkCompanyDetailEntity {
  const WorkCompanyDetailEntity({
    required this.companyId,
    required this.companyName,
    required this.profileDocumentId,
    required this.companyLogoPath,
    required this.documentsCount,
    required this.totalStorageBytes,
    required this.storageQuotaBytes,
    required this.lastAccessAt,
    required this.startedAt,
    required this.finishedAt,
    required this.roleLabel,
    required this.contactLabel,
    required this.addressLabel,
    required this.folderSummaries,
    required this.recentActivity,
    required this.statements,
  });

  final String companyId;
  final String companyName;
  final String? profileDocumentId;
  final String? companyLogoPath;
  final int documentsCount;
  final int totalStorageBytes;
  final int storageQuotaBytes;
  final DateTime? lastAccessAt;
  final DateTime? startedAt;
  final DateTime? finishedAt;
  final String roleLabel;
  final String contactLabel;
  final String addressLabel;
  final List<WorkCompanyFolderSummaryEntity> folderSummaries;
  final List<WorkCompanyRecentActivityEntity> recentActivity;
  final List<WorkStatementEntity> statements;
}
