enum ExpiryUrgency { expired, critical, warning, safe }

class DocumentExpiryItemEntity {
  const DocumentExpiryItemEntity({
    required this.documentId,
    required this.title,
    required this.documentType,
    required this.expiryDate,
    required this.urgency,
    this.daysRemaining,
  });

  final String documentId;
  final String title;
  final String documentType;
  final DateTime expiryDate;
  final ExpiryUrgency urgency;
  final int? daysRemaining;
}
