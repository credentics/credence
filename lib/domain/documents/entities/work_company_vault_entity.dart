class WorkCompanyVaultEntity {
  const WorkCompanyVaultEntity({
    required this.companyId,
    required this.companyName,
    required this.profileDocumentId,
    required this.documentsCount,
    required this.lastUpdatedAt,
    required this.lastAccessAt,
    required this.isPinned,
    required this.totalStorageBytes,
    required this.roleLabel,
    required this.contactLabel,
    required this.addressLabel,
    required this.startedAt,
    required this.finishedAt,
    required this.companyLogoPath,
  });

  final String companyId;
  final String companyName;
  final String? profileDocumentId;
  final int documentsCount;
  final DateTime lastUpdatedAt;
  final DateTime? lastAccessAt;
  final bool isPinned;
  final int totalStorageBytes;
  final String roleLabel;
  final String contactLabel;
  final String addressLabel;
  final DateTime? startedAt;
  final DateTime? finishedAt;
  final String? companyLogoPath;
}
