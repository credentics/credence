enum IdentityDocumentHolderRelation {
  owner,
  family,
  parent,
  wife,
  husband,
  son,
  daughter,
  other,
}

extension IdentityDocumentHolderRelationX on IdentityDocumentHolderRelation {
  String get storageKey => switch (this) {
    IdentityDocumentHolderRelation.owner => 'owner',
    IdentityDocumentHolderRelation.family => 'family',
    IdentityDocumentHolderRelation.parent => 'parent',
    IdentityDocumentHolderRelation.wife => 'wife',
    IdentityDocumentHolderRelation.husband => 'husband',
    IdentityDocumentHolderRelation.son => 'son',
    IdentityDocumentHolderRelation.daughter => 'daughter',
    IdentityDocumentHolderRelation.other => 'other',
  };

  String get label => switch (this) {
    IdentityDocumentHolderRelation.owner => 'Owner',
    IdentityDocumentHolderRelation.family => 'Family',
    IdentityDocumentHolderRelation.parent => 'Parent',
    IdentityDocumentHolderRelation.wife => 'Wife',
    IdentityDocumentHolderRelation.husband => 'Husband',
    IdentityDocumentHolderRelation.son => 'Son',
    IdentityDocumentHolderRelation.daughter => 'Daughter',
    IdentityDocumentHolderRelation.other => 'Other',
  };
}

IdentityDocumentHolderRelation parseIdentityDocumentHolderRelation(
  String? raw,
) {
  final normalized = (raw ?? '').trim().toLowerCase();
  return switch (normalized) {
    'owner' || 'self' || 'me' => IdentityDocumentHolderRelation.owner,
    'family' => IdentityDocumentHolderRelation.family,
    'parent' || 'father' || 'mother' => IdentityDocumentHolderRelation.parent,
    'wife' || 'spouse_female' => IdentityDocumentHolderRelation.wife,
    'husband' || 'spouse_male' => IdentityDocumentHolderRelation.husband,
    'son' => IdentityDocumentHolderRelation.son,
    'daughter' => IdentityDocumentHolderRelation.daughter,
    'other' => IdentityDocumentHolderRelation.other,
    _ => IdentityDocumentHolderRelation.owner,
  };
}
