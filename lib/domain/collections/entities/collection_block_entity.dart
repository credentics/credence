import 'package:pass_doc_manager/domain/collections/entities/collection_block_type.dart';
import 'package:pass_doc_manager/domain/collections/entities/collection_checklist_item_entity.dart';

class CollectionBlockEntity {
  const CollectionBlockEntity({
    required this.id,
    required this.collectionId,
    required this.parentBlockId,
    required this.type,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.createdAt,
    required this.updatedAt,
    required this.imageUrl,
    required this.fileType,
    required this.fileSizeLabel,
    required this.url,
    required this.domainLabel,
    required this.currencyCode,
    required this.amount,
    required this.eventAt,
    required this.expiryDate,
    required this.latitude,
    required this.longitude,
    required this.locationLabel,
    required this.isCompleted,
    required this.statusLabel,
    required this.tags,
    required this.metadata,
    required this.checklistItems,
    this.position = 0,
    this.filePath,
    this.repeatInterval,
  });

  final String id;
  final String collectionId;
  final String? parentBlockId;
  final CollectionBlockType type;
  final String title;
  final String subtitle;
  final String description;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? imageUrl;
  final String? fileType;
  final String? fileSizeLabel;
  final String? url;
  final String? domainLabel;
  final String? currencyCode;
  final double? amount;
  final DateTime? eventAt;
  final DateTime? expiryDate;
  final double? latitude;
  final double? longitude;
  final String? locationLabel;
  final bool isCompleted;
  final String? statusLabel;
  final List<String> tags;
  final Map<String, String> metadata;
  final List<CollectionChecklistItemEntity> checklistItems;
  final int position;
  final String? filePath;
  final String? repeatInterval;

  bool get isFolder => type == CollectionBlockType.folder;
  bool get isSection => type == CollectionBlockType.section;

  CollectionBlockEntity copyWith({
    String? id,
    String? collectionId,
    String? parentBlockId,
    bool clearParentBlockId = false,
    CollectionBlockType? type,
    String? title,
    String? subtitle,
    String? description,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? imageUrl,
    bool clearImageUrl = false,
    String? fileType,
    bool clearFileType = false,
    String? fileSizeLabel,
    bool clearFileSizeLabel = false,
    String? url,
    bool clearUrl = false,
    String? domainLabel,
    bool clearDomainLabel = false,
    String? currencyCode,
    bool clearCurrencyCode = false,
    double? amount,
    bool clearAmount = false,
    DateTime? eventAt,
    bool clearEventAt = false,
    DateTime? expiryDate,
    bool clearExpiryDate = false,
    double? latitude,
    bool clearLatitude = false,
    double? longitude,
    bool clearLongitude = false,
    String? locationLabel,
    bool clearLocationLabel = false,
    bool? isCompleted,
    String? statusLabel,
    bool clearStatusLabel = false,
    List<String>? tags,
    Map<String, String>? metadata,
    List<CollectionChecklistItemEntity>? checklistItems,
    int? position,
    String? filePath,
    bool clearFilePath = false,
    String? repeatInterval,
    bool clearRepeatInterval = false,
  }) {
    return CollectionBlockEntity(
      id: id ?? this.id,
      collectionId: collectionId ?? this.collectionId,
      parentBlockId: clearParentBlockId
          ? null
          : (parentBlockId ?? this.parentBlockId),
      type: type ?? this.type,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      imageUrl: clearImageUrl ? null : (imageUrl ?? this.imageUrl),
      fileType: clearFileType ? null : (fileType ?? this.fileType),
      fileSizeLabel: clearFileSizeLabel
          ? null
          : (fileSizeLabel ?? this.fileSizeLabel),
      url: clearUrl ? null : (url ?? this.url),
      domainLabel: clearDomainLabel ? null : (domainLabel ?? this.domainLabel),
      currencyCode: clearCurrencyCode
          ? null
          : (currencyCode ?? this.currencyCode),
      amount: clearAmount ? null : (amount ?? this.amount),
      eventAt: clearEventAt ? null : (eventAt ?? this.eventAt),
      expiryDate: clearExpiryDate ? null : (expiryDate ?? this.expiryDate),
      latitude: clearLatitude ? null : (latitude ?? this.latitude),
      longitude: clearLongitude ? null : (longitude ?? this.longitude),
      locationLabel: clearLocationLabel
          ? null
          : (locationLabel ?? this.locationLabel),
      isCompleted: isCompleted ?? this.isCompleted,
      statusLabel: clearStatusLabel ? null : (statusLabel ?? this.statusLabel),
      tags: tags ?? this.tags,
      metadata: metadata ?? this.metadata,
      checklistItems: checklistItems ?? this.checklistItems,
      position: position ?? this.position,
      filePath: clearFilePath ? null : (filePath ?? this.filePath),
      repeatInterval: clearRepeatInterval
          ? null
          : (repeatInterval ?? this.repeatInterval),
    );
  }
}
