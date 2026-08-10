enum CredentialCategory {
  general,
  work,
  finance,
  social,
  shopping,
  entertainment,
  developer,
}

const List<CredentialCategory> credentialCategoryValues = [
  CredentialCategory.general,
  CredentialCategory.work,
  CredentialCategory.finance,
  CredentialCategory.social,
  CredentialCategory.shopping,
  CredentialCategory.entertainment,
  CredentialCategory.developer,
];

extension CredentialCategoryX on CredentialCategory {
  String get storageKey => switch (this) {
    CredentialCategory.general => 'general',
    CredentialCategory.work => 'work',
    CredentialCategory.finance => 'finance',
    CredentialCategory.social => 'social',
    CredentialCategory.shopping => 'shopping',
    CredentialCategory.entertainment => 'entertainment',
    CredentialCategory.developer => 'developer',
  };

  String get label => switch (this) {
    CredentialCategory.general => 'General',
    CredentialCategory.work => 'Work',
    CredentialCategory.finance => 'Finance',
    CredentialCategory.social => 'Social',
    CredentialCategory.shopping => 'Shopping',
    CredentialCategory.entertainment => 'Entertainment',
    CredentialCategory.developer => 'Developer',
  };
}

CredentialCategory parseCredentialCategory(String? raw) {
  switch (raw?.trim().toLowerCase()) {
    case 'work':
      return CredentialCategory.work;
    case 'finance':
      return CredentialCategory.finance;
    case 'social':
      return CredentialCategory.social;
    case 'shopping':
      return CredentialCategory.shopping;
    case 'entertainment':
      return CredentialCategory.entertainment;
    case 'developer':
      return CredentialCategory.developer;
    case 'general':
    default:
      return CredentialCategory.general;
  }
}
