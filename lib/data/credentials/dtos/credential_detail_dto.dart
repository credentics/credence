class CredentialDetailDto {
  const CredentialDetailDto({
    required this.id,
    required this.serviceName,
    required this.accountLabel,
    required this.username,
    required this.categoryKey,
    required this.password,
    required this.url,
    required this.notes,
    required this.lastSecurityUpdate,
    required this.mfaRecovery,
    required this.isSecure,
    required this.brandHex,
    required this.logoPath,
    this.breachedCount = 0,
    this.isFavorite = false,
  });

  final String id;
  final String serviceName;
  final String accountLabel;
  final String username;
  final String categoryKey;
  final String password;
  final String url;
  final String notes;
  final String lastSecurityUpdate;
  final String mfaRecovery;
  final bool isSecure;
  final int brandHex;
  final String? logoPath;
  final int breachedCount;
  final bool isFavorite;

  factory CredentialDetailDto.fromMap(Map<String, dynamic> map) {
    return CredentialDetailDto(
      id: map['id'] as String,
      serviceName: map['serviceName'] as String,
      accountLabel: map['accountLabel'] as String,
      username: map['username'] as String,
      categoryKey: (map['category'] as String?) ?? 'general',
      password: map['password'] as String,
      url: map['url'] as String? ?? '',
      notes: map['notes'] as String? ?? '',
      lastSecurityUpdate: map['lastSecurityUpdate'] as String,
      mfaRecovery: map['mfaRecovery'] as String,
      isSecure: map['isSecure'] as bool,
      brandHex: map['brandHex'] as int,
      logoPath: map['logoPath'] as String?,
      breachedCount: (map['breachedCount'] as int?) ?? 0,
      isFavorite: (map['isFavorite'] as bool?) ?? false,
    );
  }
}
