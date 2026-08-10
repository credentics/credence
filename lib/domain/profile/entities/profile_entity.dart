class ProfileEntity {
  const ProfileEntity({
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phone,
    required this.address,
    required this.socialLinks,
    required this.photoPath,
    required this.updatedAt,
  });

  final String firstName;
  final String lastName;
  final String email;
  final String phone;
  final String address;
  final String socialLinks;
  final String photoPath;
  final DateTime updatedAt;

  String get fullName {
    final combined = '$firstName $lastName'.replaceAll(RegExp(r'\\s+'), ' ').trim();
    if (combined.isNotEmpty) {
      return combined;
    }
    return 'Vault Owner';
  }

  ProfileEntity copyWith({
    String? firstName,
    String? lastName,
    String? email,
    String? phone,
    String? address,
    String? socialLinks,
    String? photoPath,
    DateTime? updatedAt,
  }) {
    return ProfileEntity(
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      socialLinks: socialLinks ?? this.socialLinks,
      photoPath: photoPath ?? this.photoPath,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
