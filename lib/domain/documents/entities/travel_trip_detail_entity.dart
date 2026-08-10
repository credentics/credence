import 'package:pass_doc_manager/domain/documents/entities/travel_budget_entity.dart';
import 'package:pass_doc_manager/domain/documents/entities/travel_document_entity.dart';
import 'package:pass_doc_manager/domain/documents/entities/travel_expense_entity.dart';
import 'package:pass_doc_manager/domain/documents/entities/travel_trip_entity.dart';
import 'package:pass_doc_manager/domain/documents/entities/travel_timeline_event_entity.dart';

class TravelTripDetailEntity {
  const TravelTripDetailEntity({
    required this.trip,
    required this.timelineEvents,
    required this.expenses,
    required this.walletDocuments,
    required this.destinationsCount,
    required this.budget,
    required this.upcomingReminderTitle,
    required this.upcomingReminderSubtitle,
  });

  final TravelTripEntity trip;
  final List<TravelTimelineEventEntity> timelineEvents;
  final List<TravelExpenseEntity> expenses;
  final List<TravelDocumentEntity> walletDocuments;
  final int destinationsCount;
  final TravelBudgetEntity? budget;
  final String upcomingReminderTitle;
  final String upcomingReminderSubtitle;
}

