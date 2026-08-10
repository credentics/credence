class VaultPasswordRecordEntity {
  const VaultPasswordRecordEntity({
    required this.id,
    required this.serviceName,
    required this.username,
    required this.secret,
    required this.updatedAtIso,
  });

  final String id;
  final String serviceName;
  final String username;
  final String secret;
  final String updatedAtIso;
}
