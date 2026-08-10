enum DocumentCategoryType {
  identity,
  work,
  property,
  vehicle,
  health,
  travel,
  other,
}

extension DocumentCategoryTypeX on DocumentCategoryType {
  String get key {
    return switch (this) {
      DocumentCategoryType.identity => 'identity',
      DocumentCategoryType.work => 'work',
      DocumentCategoryType.property => 'property',
      DocumentCategoryType.vehicle => 'vehicle',
      DocumentCategoryType.health => 'health',
      DocumentCategoryType.travel => 'travel',
      DocumentCategoryType.other => 'other',
    };
  }

  String get label {
    return switch (this) {
      DocumentCategoryType.identity => 'Identity',
      DocumentCategoryType.work => 'Work',
      DocumentCategoryType.property => 'Property',
      DocumentCategoryType.vehicle => 'Vehicle',
      DocumentCategoryType.health => 'Health',
      DocumentCategoryType.travel => 'Travel',
      DocumentCategoryType.other => 'Other',
    };
  }
}
