class VaultDocumentRecordEntity {
  const VaultDocumentRecordEntity({
    required this.id,
    required this.title,
    required this.category,
    required this.updatedAtIso,
  });

  final String id;
  final String title;
  final String category;
  final String updatedAtIso;
}
