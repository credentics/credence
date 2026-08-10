enum TravelExpenseCategory {
  foodDining,
  transport,
  activities,
  accommodation,
  shopping,
  other,
}

TravelExpenseCategory parseTravelExpenseCategory(String rawValue) {
  final normalized = rawValue.trim().toLowerCase();
  return switch (normalized) {
    'food_dining' || 'food' || 'dining' || 'restaurant' =>
      TravelExpenseCategory.foodDining,
    'transport' || 'travel' || 'mobility' => TravelExpenseCategory.transport,
    'activities' || 'activity' || 'tickets' => TravelExpenseCategory.activities,
    'accommodation' || 'stay' || 'lodging' || 'hotel' =>
      TravelExpenseCategory.accommodation,
    'shopping' => TravelExpenseCategory.shopping,
    _ => TravelExpenseCategory.other,
  };
}

extension TravelExpenseCategoryX on TravelExpenseCategory {
  String get key {
    return switch (this) {
      TravelExpenseCategory.foodDining => 'food_dining',
      TravelExpenseCategory.transport => 'transport',
      TravelExpenseCategory.activities => 'activities',
      TravelExpenseCategory.accommodation => 'accommodation',
      TravelExpenseCategory.shopping => 'shopping',
      TravelExpenseCategory.other => 'other',
    };
  }
}

