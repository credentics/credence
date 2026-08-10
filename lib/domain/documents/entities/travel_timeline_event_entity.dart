import 'package:pass_doc_manager/domain/documents/entities/trip_event_category.dart';

class TravelTimelineEventEntity {
  const TravelTimelineEventEntity({
    required this.eventId,
    required this.tripId,
    required this.category,
    required this.title,
    required this.locationLabel,
    required this.startAt,
    required this.providerLabel,
    required this.confirmationCode,
    required this.documentsCount,
    required this.notes,
    required this.previewImagePath,
    required this.updatedAt,
  });

  final String eventId;
  final String tripId;
  final TripEventCategory category;
  final String title;
  final String locationLabel;
  final DateTime startAt;
  final String providerLabel;
  final String confirmationCode;
  final int documentsCount;
  final String notes;
  final String? previewImagePath;
  final DateTime updatedAt;
}

