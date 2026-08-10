class ProfileShareOptionsDto {
  const ProfileShareOptionsDto({
    required this.enabledAttributeKeys,
    required this.linkExpirationHours,
  });

  final List<String> enabledAttributeKeys;
  final int linkExpirationHours;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'enabledAttributeKeys': enabledAttributeKeys,
      'linkExpirationHours': linkExpirationHours,
    };
  }

  factory ProfileShareOptionsDto.fromMap(Map<String, dynamic> map) {
    final rawKeys = map['enabledAttributeKeys'];
    final keys = rawKeys is List
        ? rawKeys.map((item) => item.toString().trim()).where((item) => item.isNotEmpty).toList(growable: false)
        : const <String>[];
    final expiration = map['linkExpirationHours'] is num
        ? (map['linkExpirationHours'] as num).toInt()
        : 24;

    return ProfileShareOptionsDto(
      enabledAttributeKeys: keys,
      linkExpirationHours: expiration,
    );
  }

  static const defaults = ProfileShareOptionsDto(
    enabledAttributeKeys: ['full_name', 'email', 'social_links'],
    linkExpirationHours: 24,
  );
}
