class TravelTripEntity {
  const TravelTripEntity({
    required this.tripId,
    required this.profileDocumentId,
    required this.title,
    required this.destinationSummary,
    required this.notes,
    required this.startDate,
    required this.endDate,
    required this.coverImagePath,
    required this.timelineEventsCount,
    required this.documentsCount,
    required this.expensesCount,
    required this.totalSpent,
    required this.currencyCode,
    required this.lastUpdatedAt,
  });

  final String tripId;
  final String? profileDocumentId;
  final String title;
  final String destinationSummary;
  final String notes;
  final DateTime startDate;
  final DateTime endDate;
  final String? coverImagePath;
  final int timelineEventsCount;
  final int documentsCount;
  final int expensesCount;
  final double totalSpent;
  final String currencyCode;
  final DateTime lastUpdatedAt;
}
