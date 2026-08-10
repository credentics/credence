enum ProfileShareAttribute {
  fullName,
  email,
  phone,
  homeAddress,
  socialLinks,
}

extension ProfileShareAttributeX on ProfileShareAttribute {
  String get storageKey => switch (this) {
    ProfileShareAttribute.fullName => 'full_name',
    ProfileShareAttribute.email => 'email',
    ProfileShareAttribute.phone => 'phone',
    ProfileShareAttribute.homeAddress => 'home_address',
    ProfileShareAttribute.socialLinks => 'social_links',
  };

  String get title => switch (this) {
    ProfileShareAttribute.fullName => 'Full Name',
    ProfileShareAttribute.email => 'Email Address',
    ProfileShareAttribute.phone => 'Phone Number',
    ProfileShareAttribute.homeAddress => 'Home Address',
    ProfileShareAttribute.socialLinks => 'Social Links',
  };

  String get iconHint => switch (this) {
    ProfileShareAttribute.fullName => 'person',
    ProfileShareAttribute.email => 'email',
    ProfileShareAttribute.phone => 'phone',
    ProfileShareAttribute.homeAddress => 'address',
    ProfileShareAttribute.socialLinks => 'link',
  };
}

ProfileShareAttribute? parseProfileShareAttribute(String raw) {
  final normalized = raw.trim().toLowerCase();
  for (final value in ProfileShareAttribute.values) {
    if (value.storageKey == normalized) {
      return value;
    }
  }
  return null;
}
