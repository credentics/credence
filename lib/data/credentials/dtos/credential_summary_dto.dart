class CredentialSummaryDto {
  const CredentialSummaryDto({
    required this.id,
    required this.displayName,
    required this.username,
    required this.categoryKey,
    required this.brandHex,
    required this.hasWarning,
    required this.logoPath,
    required this.createdAtIso,
    required this.lastUsedAtIso,
    this.breachedCount = 0,
    this.isFavorite = false,
    this.isReused = false,
    this.isMissingUrl = false,
  });

  final String id;
  final String displayName;
  final String username;
  final String categoryKey;
  final int brandHex;
  final bool hasWarning;
  final String? logoPath;
  final String? createdAtIso;
  final String? lastUsedAtIso;
  final int breachedCount;
  final bool isFavorite;
  final bool isReused;
  final bool isMissingUrl;

  factory CredentialSummaryDto.fromMap(Map<String, dynamic> map) {
    return CredentialSummaryDto(
      id: map['id'] as String,
      displayName: map['displayName'] as String,
      username: map['username'] as String,
      categoryKey: (map['category'] as String?) ?? 'general',
      brandHex: map['brandHex'] as int,
      hasWarning: map['hasWarning'] as bool,
      logoPath: map['logoPath'] as String?,
      createdAtIso: map['createdAtIso'] as String?,
      lastUsedAtIso: map['lastUsedAtIso'] as String?,
      breachedCount: (map['breachedCount'] as int?) ?? 0,
      isFavorite: (map['isFavorite'] as bool?) ?? false,
      isReused: (map['isReused'] as bool?) ?? false,
      isMissingUrl: (map['isMissingUrl'] as bool?) ?? false,
    );
  }
}
