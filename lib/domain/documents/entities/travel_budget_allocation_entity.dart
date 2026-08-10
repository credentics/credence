import 'package:pass_doc_manager/domain/documents/entities/travel_expense_category.dart';

class TravelBudgetAllocationEntity {
  const TravelBudgetAllocationEntity({
    required this.category,
    required this.amount,
  });

  final TravelExpenseCategory category;
  final double amount;
}

