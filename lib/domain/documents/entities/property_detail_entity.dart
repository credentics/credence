import 'package:pass_doc_manager/domain/documents/entities/property_asset_summary_entity.dart';

class PropertyDetailEntity {
  const PropertyDetailEntity({
    required this.propertyId,
    required this.propertyName,
    required this.propertyTypeLabel,
    required this.ownershipStatusLabel,
    required this.fullAddress,
    required this.addressSuggestionJson,
    required this.occupancyStatusLabel,
    required this.monthlyAmountLabel,
    required this.lastUpdatedAt,
    required this.lastActivityLabel,
    required this.profileDocumentId,
    required this.assetSummaries,
  });

  final String propertyId;
  final String propertyName;
  final String propertyTypeLabel;
  final String ownershipStatusLabel;
  final String fullAddress;
  final String addressSuggestionJson;
  final String occupancyStatusLabel;
  final String monthlyAmountLabel;
  final DateTime lastUpdatedAt;
  final String lastActivityLabel;
  final String? profileDocumentId;
  final List<PropertyAssetSummaryEntity> assetSummaries;
}
