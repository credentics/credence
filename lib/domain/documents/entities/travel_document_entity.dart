class TravelDocumentEntity {
  const TravelDocumentEntity({
    required this.documentId,
    required this.tripId,
    required this.title,
    required this.documentTypeLabel,
    required this.fileName,
    required this.fileSizeLabel,
    required this.updatedAt,
    required this.filePath,
    required this.linkedEventId,
  });

  final String documentId;
  final String tripId;
  final String title;
  final String documentTypeLabel;
  final String fileName;
  final String fileSizeLabel;
  final DateTime updatedAt;
  final String? filePath;
  final String? linkedEventId;
}

