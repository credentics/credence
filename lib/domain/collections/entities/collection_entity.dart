import 'package:pass_doc_manager/domain/collections/entities/collection_block_entity.dart';
import 'package:pass_doc_manager/domain/collections/entities/collection_block_type.dart';

class CollectionEntity {
  const CollectionEntity({
    required this.id,
    required this.name,
    required this.subtitle,
    required this.iconKey,
    this.iconEmoji,
    this.iconImagePath,
    required this.accentColorHex,
    required this.startDate,
    required this.endDate,
    required this.coverImageUrl,
    required this.updatedAt,
    required this.blocks,
    this.position = 0,
    this.isPinLocked = false,
    this.pinHash = '',
  });

  final String id;
  final String name;
  final String subtitle;
  final String iconKey;
  final String? iconEmoji;
  final String? iconImagePath;
  final String accentColorHex;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? coverImageUrl;
  final DateTime updatedAt;
  final List<CollectionBlockEntity> blocks;
  final int position;
  final bool isPinLocked;
  final String pinHash;

  int get totalItemsCount => blocks.length;

  int countByType(CollectionBlockType type) {
    return blocks.where((block) => block.type == type).length;
  }

  List<CollectionBlockEntity> rootBlocks() {
    return blocks.where((block) => block.parentBlockId == null).toList();
  }

  CollectionEntity copyWith({
    String? id,
    String? name,
    String? subtitle,
    String? iconKey,
    String? iconEmoji,
    bool clearIconEmoji = false,
    String? iconImagePath,
    bool clearIconImagePath = false,
    String? accentColorHex,
    DateTime? startDate,
    bool clearStartDate = false,
    DateTime? endDate,
    bool clearEndDate = false,
    String? coverImageUrl,
    bool clearCoverImageUrl = false,
    DateTime? updatedAt,
    List<CollectionBlockEntity>? blocks,
    int? position,
    bool? isPinLocked,
    String? pinHash,
  }) {
    return CollectionEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      subtitle: subtitle ?? this.subtitle,
      iconKey: iconKey ?? this.iconKey,
      iconEmoji: clearIconEmoji ? null : (iconEmoji ?? this.iconEmoji),
      iconImagePath: clearIconImagePath
          ? null
          : (iconImagePath ?? this.iconImagePath),
      accentColorHex: accentColorHex ?? this.accentColorHex,
      startDate: clearStartDate ? null : (startDate ?? this.startDate),
      endDate: clearEndDate ? null : (endDate ?? this.endDate),
      coverImageUrl: clearCoverImageUrl
          ? null
          : (coverImageUrl ?? this.coverImageUrl),
      updatedAt: updatedAt ?? this.updatedAt,
      blocks: blocks ?? this.blocks,
      position: position ?? this.position,
      isPinLocked: isPinLocked ?? this.isPinLocked,
      pinHash: pinHash ?? this.pinHash,
    );
  }
}
