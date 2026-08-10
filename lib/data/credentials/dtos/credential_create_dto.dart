class CredentialCreateDto {
  const CredentialCreateDto({
    required this.serviceName,
    required this.accountLabel,
    required this.username,
    required this.categoryKey,
    required this.password,
    required this.url,
    required this.notes,
    required this.brandHex,
    required this.logoPath,
  });

  final String serviceName;
  final String accountLabel;
  final String username;
  final String categoryKey;
  final String password;
  final String url;
  final String notes;
  final int brandHex;
  final String? logoPath;
}
