class PropertyVaultEntity {
  const PropertyVaultEntity({
    required this.propertyId,
    required this.propertyName,
    required this.propertyTypeLabel,
    required this.ownershipStatusLabel,
    required this.fullAddress,
    required this.addressSuggestionJson,
    required this.lastUpdatedAt,
    required this.documentsCount,
    required this.profileDocumentId,
  });

  final String propertyId;
  final String propertyName;
  final String propertyTypeLabel;
  final String ownershipStatusLabel;
  final String fullAddress;
  final String addressSuggestionJson;
  final DateTime lastUpdatedAt;
  final int documentsCount;
  final String? profileDocumentId;
}
