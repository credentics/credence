enum IdentityDocumentGroup { personal, travel }

extension IdentityDocumentGroupX on IdentityDocumentGroup {
  String get key {
    return switch (this) {
      IdentityDocumentGroup.personal => 'personal',
      IdentityDocumentGroup.travel => 'travel',
    };
  }

  String get label {
    return switch (this) {
      IdentityDocumentGroup.personal => 'Personal',
      IdentityDocumentGroup.travel => 'Travel',
    };
  }
}
