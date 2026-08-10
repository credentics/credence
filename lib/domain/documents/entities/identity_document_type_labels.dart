class IdentityDocumentTypeLabels {
  const IdentityDocumentTypeLabels._();

  static const String passport = 'passport';
  static const String driversLicense = 'drivers_license';
  static const String idCard = 'id_card';
  static const String nationalId = 'national_id';
  static const String residencePermit = 'residence_permit';
  static const String proofOfAgeCard = 'proof_of_age_card';
  static const String studentId = 'student_id';
  static const String disabilityCard = 'disability_card';
  static const String unknown = 'unknown';

  static String normalizeRawTypeKey(String raw) {
    final normalized = raw
        .trim()
        .toLowerCase()
        .replaceAll('-', '_')
        .replaceAll(RegExp(r'\s+'), '_');

    return switch (normalized) {
      'passport' => passport,
      'drivers_license' ||
      'driver_license' ||
      'drivers_licence' ||
      'driver_licence' => driversLicense,
      'national_id' || 'nationalid' => nationalId,
      'id_card' || 'idcard' => idCard,
      'residence_permit' || 'residency_permit' => residencePermit,
      'proof_of_age_card' || 'proofofagecard' => proofOfAgeCard,
      'student_id' || 'studentid' => studentId,
      'disability_card' || 'disabilitycard' => disabilityCard,
      'unknown' => unknown,
      _ => normalized,
    };
  }

  static String labelFromRawType(String raw) {
    final normalized = normalizeRawTypeKey(raw);
    return switch (normalized) {
      passport => 'Passport',
      driversLicense => "Driver's License",
      nationalId || idCard => 'National ID',
      residencePermit => 'Residence Permit',
      proofOfAgeCard => 'Proof of Age Card',
      studentId => 'Student ID',
      disabilityCard => 'Disability Card',
      unknown => 'Unknown',
      _ => _toSentenceCase(normalized),
    };
  }

  static String _toSentenceCase(String raw) {
    final value = raw.trim();
    if (value.isEmpty) {
      return 'Document';
    }

    return value
        .split(RegExp(r'[_\-\s]+'))
        .where((part) => part.trim().isNotEmpty)
        .map((part) {
          if (part.length <= 2) {
            return part.toUpperCase();
          }
          return '${part[0].toUpperCase()}${part.substring(1)}';
        })
        .join(' ');
  }
}
