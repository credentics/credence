class ProfileRecordDto {
  const ProfileRecordDto({
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phone,
    required this.address,
    required this.socialLinks,
    required this.photoPath,
    required this.updatedAtIso,
  });

  final String firstName;
  final String lastName;
  final String email;
  final String phone;
  final String address;
  final String socialLinks;
  final String photoPath;
  final String updatedAtIso;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'phone': phone,
      'address': address,
      'socialLinks': socialLinks,
      'photoPath': photoPath,
      'updatedAtIso': updatedAtIso,
    };
  }

  factory ProfileRecordDto.fromMap(Map<String, dynamic> map) {
    return ProfileRecordDto(
      firstName: (map['firstName'] as String? ?? '').trim(),
      lastName: (map['lastName'] as String? ?? '').trim(),
      email: (map['email'] as String? ?? '').trim(),
      phone: (map['phone'] as String? ?? '').trim(),
      address: (map['address'] as String? ?? '').trim(),
      socialLinks: (map['socialLinks'] as String? ?? '').trim(),
      photoPath: (map['photoPath'] as String? ?? '').trim(),
      updatedAtIso: (map['updatedAtIso'] as String? ?? '').trim(),
    );
  }

  static ProfileRecordDto defaults(DateTime now) {
    return ProfileRecordDto(
      firstName: '',
      lastName: '',
      email: '',
      phone: '',
      address: '',
      socialLinks: '',
      photoPath: '',
      updatedAtIso: now.toIso8601String(),
    );
  }
}
