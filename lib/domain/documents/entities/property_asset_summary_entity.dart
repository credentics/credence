import 'package:pass_doc_manager/domain/documents/entities/property_asset_type.dart';

class PropertyAssetSummaryEntity {
  const PropertyAssetSummaryEntity({
    required this.assetType,
    required this.itemsCount,
  });

  final PropertyAssetType assetType;
  final int itemsCount;
}
