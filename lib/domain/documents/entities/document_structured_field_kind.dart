enum DocumentStructuredFieldKind {
  identifier,
  fullName,
  country,
  nationality,
  birthDate,
  issueDate,
  expiryDate,
  issuingAuthority,
  categories,
  category,
  updated,
  unknown,
}

class DocumentStructuredFieldMapKeys {
  const DocumentStructuredFieldMapKeys._();

  static const key = 'key';
  static const label = 'label';
  static const value = 'value';
}

extension DocumentStructuredFieldKindX on DocumentStructuredFieldKind {
  String get raw {
    return switch (this) {
      DocumentStructuredFieldKind.identifier => 'identifier',
      DocumentStructuredFieldKind.fullName => 'full_name',
      DocumentStructuredFieldKind.country => 'country',
      DocumentStructuredFieldKind.nationality => 'nationality',
      DocumentStructuredFieldKind.birthDate => 'birth_date',
      DocumentStructuredFieldKind.issueDate => 'issue_date',
      DocumentStructuredFieldKind.expiryDate => 'expiry_date',
      DocumentStructuredFieldKind.issuingAuthority => 'issuing_authority',
      DocumentStructuredFieldKind.categories => 'categories',
      DocumentStructuredFieldKind.category => 'category',
      DocumentStructuredFieldKind.updated => 'updated',
      DocumentStructuredFieldKind.unknown => 'unknown',
    };
  }
}

DocumentStructuredFieldKind documentStructuredFieldKindFromRaw(String raw) {
  final normalized = raw.trim().toLowerCase();
  return switch (normalized) {
    'identifier' => DocumentStructuredFieldKind.identifier,
    'full_name' => DocumentStructuredFieldKind.fullName,
    'country' => DocumentStructuredFieldKind.country,
    'nationality' => DocumentStructuredFieldKind.nationality,
    'birth_date' => DocumentStructuredFieldKind.birthDate,
    'issue_date' => DocumentStructuredFieldKind.issueDate,
    'expiry_date' => DocumentStructuredFieldKind.expiryDate,
    'issuing_authority' => DocumentStructuredFieldKind.issuingAuthority,
    'categories' => DocumentStructuredFieldKind.categories,
    'category' => DocumentStructuredFieldKind.category,
    'updated' => DocumentStructuredFieldKind.updated,
    _ => DocumentStructuredFieldKind.unknown,
  };
}

DocumentStructuredFieldKind documentStructuredFieldKindFromLabel(String label) {
  final normalized = label.trim().toLowerCase();
  return switch (normalized) {
    'passport number' ||
    'document number' ||
    'id number' ||
    'identity id' ||
    'license number' ||
    'permit number' ||
    'document id' =>
      DocumentStructuredFieldKind.identifier,
    'full name' => DocumentStructuredFieldKind.fullName,
    'country' || 'issuing country' => DocumentStructuredFieldKind.country,
    'nationality' => DocumentStructuredFieldKind.nationality,
    'birth date' || 'dob' => DocumentStructuredFieldKind.birthDate,
    'issue date' => DocumentStructuredFieldKind.issueDate,
    'expiry date' => DocumentStructuredFieldKind.expiryDate,
    'issuing authority' => DocumentStructuredFieldKind.issuingAuthority,
    'categories' => DocumentStructuredFieldKind.categories,
    'category' => DocumentStructuredFieldKind.category,
    'updated' => DocumentStructuredFieldKind.updated,
    _ => DocumentStructuredFieldKind.unknown,
  };
}
