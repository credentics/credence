class VaultPasswordRecordDto {
  const VaultPasswordRecordDto({
    required this.id,
    required this.serviceName,
    required this.username,
    required this.secret,
    required this.updatedAtIso,
    this.displayName,
    this.accountLabel,
    this.categoryKey,
    this.url,
    this.notes,
    this.lastSecurityUpdate,
    this.mfaRecovery,
    this.isSecure,
    this.hasWarning,
    this.brandHex,
    this.logoPath,
    this.lastUsedAtIso,
  });

  final String id;
  final String serviceName;
  final String username;
  final String secret;
  final String updatedAtIso;
  final String? displayName;
  final String? accountLabel;
  final String? categoryKey;
  final String? url;
  final String? notes;
  final String? lastSecurityUpdate;
  final String? mfaRecovery;
  final bool? isSecure;
  final bool? hasWarning;
  final int? brandHex;
  final String? logoPath;
  final String? lastUsedAtIso;

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'id': id,
      'serviceName': serviceName,
      'username': username,
      'secret': secret,
      'updatedAtIso': updatedAtIso,
    };
    if (displayName != null) {
      map['displayName'] = displayName;
    }
    if (accountLabel != null) {
      map['accountLabel'] = accountLabel;
    }
    if (categoryKey != null) {
      map['category'] = categoryKey;
    }
    if (url != null) {
      map['url'] = url;
    }
    if (notes != null) {
      map['notes'] = notes;
    }
    if (lastSecurityUpdate != null) {
      map['lastSecurityUpdate'] = lastSecurityUpdate;
    }
    if (mfaRecovery != null) {
      map['mfaRecovery'] = mfaRecovery;
    }
    if (isSecure != null) {
      map['isSecure'] = isSecure;
    }
    if (hasWarning != null) {
      map['hasWarning'] = hasWarning;
    }
    if (brandHex != null) {
      map['brandHex'] = brandHex;
    }
    if (logoPath != null) {
      map['logoPath'] = logoPath;
    }
    if (lastUsedAtIso != null) {
      map['lastUsedAtIso'] = lastUsedAtIso;
    }
    return map;
  }

  factory VaultPasswordRecordDto.fromMap(Map<String, dynamic> map) {
    final rawIsSecure = map['isSecure'];
    final rawHasWarning = map['hasWarning'];
    final rawBrandHex = map['brandHex'];
    return VaultPasswordRecordDto(
      id: map['id'] as String,
      serviceName: map['serviceName'] as String,
      username: map['username'] as String,
      secret: map['secret'] as String,
      updatedAtIso: map['updatedAtIso'] as String,
      displayName: map['displayName'] as String?,
      accountLabel: map['accountLabel'] as String?,
      categoryKey: map['category'] as String?,
      url: map['url'] as String?,
      notes: map['notes'] as String?,
      lastSecurityUpdate: map['lastSecurityUpdate'] as String?,
      mfaRecovery: map['mfaRecovery'] as String?,
      isSecure: _parseBool(rawIsSecure),
      hasWarning: _parseBool(rawHasWarning),
      brandHex: rawBrandHex is int
          ? rawBrandHex
          : int.tryParse(rawBrandHex?.toString() ?? ''),
      logoPath: map['logoPath'] as String?,
      lastUsedAtIso: map['lastUsedAtIso'] as String?,
    );
  }

  static bool? _parseBool(dynamic value) {
    if (value is bool) {
      return value;
    }
    if (value is num) {
      return value != 0;
    }
    final text = value?.toString().trim().toLowerCase() ?? '';
    if (text == 'true') {
      return true;
    }
    if (text == 'false') {
      return false;
    }
    return null;
  }
}
