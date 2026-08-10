import 'package:pass_doc_manager/domain/documents/entities/travel_budget_allocation_entity.dart';

class TravelBudgetEntity {
  const TravelBudgetEntity({
    required this.tripId,
    required this.totalBudget,
    required this.currencyCode,
    required this.allocations,
    required this.updatedAt,
  });

  final String tripId;
  final double totalBudget;
  final String currencyCode;
  final List<TravelBudgetAllocationEntity> allocations;
  final DateTime updatedAt;
}

