import 'package:pass_doc_manager/domain/documents/entities/property_asset_type.dart';

class PropertyAssetRecordEntity {
  const PropertyAssetRecordEntity({
    required this.documentId,
    required this.assetType,
    required this.title,
    required this.fileName,
    required this.fileSizeLabel,
    required this.updatedAt,
    required this.issueDate,
    required this.paymentAmountLabel,
    required this.paymentDate,
  });

  final String documentId;
  final PropertyAssetType assetType;
  final String title;
  final String fileName;
  final String fileSizeLabel;
  final DateTime updatedAt;
  final DateTime? issueDate;
  final String paymentAmountLabel;
  final DateTime? paymentDate;

  bool get hasPaymentDetails =>
      paymentAmountLabel.trim().isNotEmpty || paymentDate != null;
}
