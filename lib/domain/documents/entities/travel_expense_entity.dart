import 'package:pass_doc_manager/domain/documents/entities/travel_expense_category.dart';

class TravelExpenseEntity {
  const TravelExpenseEntity({
    required this.expenseId,
    required this.tripId,
    required this.category,
    required this.title,
    required this.amount,
    required this.currencyCode,
    required this.locationLabel,
    required this.occurredAt,
    required this.notes,
    required this.receiptPath,
    required this.updatedAt,
  });

  final String expenseId;
  final String tripId;
  final TravelExpenseCategory category;
  final String title;
  final double amount;
  final String currencyCode;
  final String locationLabel;
  final DateTime occurredAt;
  final String notes;
  final String? receiptPath;
  final DateTime updatedAt;
}

