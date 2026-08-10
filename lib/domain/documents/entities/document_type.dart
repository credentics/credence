enum DocumentType { passport, idCard, driversLicense, other }

extension DocumentTypeX on DocumentType {
  String get key {
    return switch (this) {
      DocumentType.passport => 'passport',
      DocumentType.idCard => 'id_card',
      DocumentType.driversLicense => 'drivers_license',
      DocumentType.other => 'other',
    };
  }

  String get label {
    return switch (this) {
      DocumentType.passport => 'Passport',
      DocumentType.idCard => 'ID Card',
      DocumentType.driversLicense => "Driver's License",
      DocumentType.other => 'Other Documents',
    };
  }
}
