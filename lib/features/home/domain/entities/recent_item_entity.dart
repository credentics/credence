enum RecentItemSourceType { credential, document, collection }

class RecentItemEntity {
  const RecentItemEntity({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.sourceType,
    required this.sourceId,
    required this.modifiedAt,
    this.previewImagePath,
  });

  final String id;
  final String title;
  final String subtitle;
  final RecentItemSourceType sourceType;
  final String sourceId;
  final DateTime modifiedAt;
  final String? previewImagePath;
}
