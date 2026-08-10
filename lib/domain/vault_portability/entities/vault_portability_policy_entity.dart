class VaultPortabilityPolicyEntity {
  const VaultPortabilityPolicyEntity({
    required this.canImportAtAnyTime,
    required this.canExportAtAnyTime,
  });

  final bool canImportAtAnyTime;
  final bool canExportAtAnyTime;
}
