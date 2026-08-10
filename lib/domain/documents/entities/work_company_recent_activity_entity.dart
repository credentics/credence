class WorkCompanyRecentActivityEntity {
  const WorkCompanyRecentActivityEntity({
    required this.documentId,
    required this.title,
    required this.subtitle,
    required this.updatedAt,
    this.filesCount = 1,
  });

  final String documentId;
  final String title;
  final String subtitle;
  final DateTime updatedAt;
  final int filesCount;
}
