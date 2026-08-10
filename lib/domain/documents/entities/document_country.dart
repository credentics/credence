enum DocumentCountry {
  unknown,
  unitedStates,
  unitedKingdom,
  france,
  germany,
  italy,
  spain,
  canada,
  switzerland,
  turkey,
  tunisia,
  unitedArabEmirates,
  europeanUnion,
}

extension DocumentCountryX on DocumentCountry {
  String get label {
    return switch (this) {
      DocumentCountry.unknown => 'Unknown',
      DocumentCountry.unitedStates => 'United States',
      DocumentCountry.unitedKingdom => 'United Kingdom',
      DocumentCountry.france => 'France',
      DocumentCountry.germany => 'Germany',
      DocumentCountry.italy => 'Italy',
      DocumentCountry.spain => 'Spain',
      DocumentCountry.canada => 'Canada',
      DocumentCountry.switzerland => 'Switzerland',
      DocumentCountry.turkey => 'Turkey',
      DocumentCountry.tunisia => 'Tunisia',
      DocumentCountry.unitedArabEmirates => 'United Arab Emirates',
      DocumentCountry.europeanUnion => 'European Union',
    };
  }
}
