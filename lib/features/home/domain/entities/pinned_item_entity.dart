class PinnedItemEntity {
  const PinnedItemEntity({
    required this.sourceType,
    required this.sourceId,
    required this.title,
    required this.subtitle,
    this.logoPath,
  });

  final String sourceType;
  final String sourceId;
  final String title;
  final String subtitle;
  final String? logoPath;
}
