enum TripEventCategory { travel, stay, dining, activity, reservation }

TripEventCategory parseTripEventCategory(String rawValue) {
  final normalized = rawValue.trim().toLowerCase();
  return switch (normalized) {
    'travel' || 'transport' || 'flight' || 'train' => TripEventCategory.travel,
    'stay' || 'hotel' || 'accommodation' => TripEventCategory.stay,
    'dining' || 'food' || 'restaurant' => TripEventCategory.dining,
    'activity' || 'tour' || 'experience' => TripEventCategory.activity,
    'reservation' || 'rental' => TripEventCategory.reservation,
    _ => TripEventCategory.travel,
  };
}

extension TripEventCategoryX on TripEventCategory {
  String get key {
    return switch (this) {
      TripEventCategory.travel => 'travel',
      TripEventCategory.stay => 'stay',
      TripEventCategory.dining => 'dining',
      TripEventCategory.activity => 'activity',
      TripEventCategory.reservation => 'reservation',
    };
  }
}

