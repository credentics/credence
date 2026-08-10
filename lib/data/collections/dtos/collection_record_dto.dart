class CollectionRecordDto {
  const CollectionRecordDto({
    required this.id,
    required this.name,
    required this.subtitle,
    required this.iconKey,
    this.iconEmoji,
    this.iconImagePath,
    required this.accentColorHex,
    required this.startDateIso,
    required this.endDateIso,
    required this.coverImageUrl,
    required this.updatedAtIso,
    required this.blocks,
    this.position = 0,
    this.isPinLocked = false,
    this.pinHash = '',
  });

  factory CollectionRecordDto.fromMap(Map<String, dynamic> map) {
    final blocksRaw = map['blocks'];
    final List<dynamic> blocksList = blocksRaw is List ? blocksRaw : const [];
    return CollectionRecordDto(
      id: _asString(map['id']),
      name: _asString(map['name']),
      subtitle: _asString(map['subtitle']),
      iconKey: _asString(map['icon_key']),
      iconEmoji: _nullableString(map['icon_emoji']),
      iconImagePath: _nullableString(map['icon_image_path']),
      accentColorHex: _asString(map['accent_color_hex']),
      startDateIso: _nullableString(map['start_date_iso']),
      endDateIso: _nullableString(map['end_date_iso']),
      coverImageUrl: _nullableString(map['cover_image_url']),
      updatedAtIso: _asString(map['updated_at_iso']),
      blocks: blocksList
          .whereType<Map>()
          .map(
            (raw) => CollectionBlockRecordDto.fromMap(
              Map<String, dynamic>.from(raw),
            ),
          )
          .toList(growable: false),
      position: (map['position'] as int?) ?? 0,
      isPinLocked: map['is_pin_locked'] == true,
      pinHash: _asString(map['pin_hash']),
    );
  }

  final String id;
  final String name;
  final String subtitle;
  final String iconKey;
  final String? iconEmoji;
  final String? iconImagePath;
  final String accentColorHex;
  final String? startDateIso;
  final String? endDateIso;
  final String? coverImageUrl;
  final String updatedAtIso;
  final List<CollectionBlockRecordDto> blocks;
  final int position;
  final bool isPinLocked;
  final String pinHash;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'subtitle': subtitle,
      'icon_key': iconKey,
      'icon_emoji': iconEmoji,
      'icon_image_path': iconImagePath,
      'accent_color_hex': accentColorHex,
      'start_date_iso': startDateIso,
      'end_date_iso': endDateIso,
      'cover_image_url': coverImageUrl,
      'updated_at_iso': updatedAtIso,
      'blocks': blocks.map((block) => block.toMap()).toList(growable: false),
      'position': position,
      'is_pin_locked': isPinLocked,
      'pin_hash': pinHash,
    };
  }

  CollectionRecordDto copyWith({
    String? id,
    String? name,
    String? subtitle,
    String? iconKey,
    String? iconEmoji,
    bool clearIconEmoji = false,
    String? iconImagePath,
    bool clearIconImagePath = false,
    String? accentColorHex,
    String? startDateIso,
    bool clearStartDateIso = false,
    String? endDateIso,
    bool clearEndDateIso = false,
    String? coverImageUrl,
    bool clearCoverImageUrl = false,
    String? updatedAtIso,
    List<CollectionBlockRecordDto>? blocks,
    int? position,
    bool? isPinLocked,
    String? pinHash,
  }) {
    return CollectionRecordDto(
      id: id ?? this.id,
      name: name ?? this.name,
      subtitle: subtitle ?? this.subtitle,
      iconKey: iconKey ?? this.iconKey,
      iconEmoji: clearIconEmoji ? null : (iconEmoji ?? this.iconEmoji),
      iconImagePath: clearIconImagePath
          ? null
          : (iconImagePath ?? this.iconImagePath),
      accentColorHex: accentColorHex ?? this.accentColorHex,
      startDateIso: clearStartDateIso
          ? null
          : (startDateIso ?? this.startDateIso),
      endDateIso: clearEndDateIso ? null : (endDateIso ?? this.endDateIso),
      coverImageUrl: clearCoverImageUrl
          ? null
          : (coverImageUrl ?? this.coverImageUrl),
      updatedAtIso: updatedAtIso ?? this.updatedAtIso,
      blocks: blocks ?? this.blocks,
      position: position ?? this.position,
      isPinLocked: isPinLocked ?? this.isPinLocked,
      pinHash: pinHash ?? this.pinHash,
    );
  }
}

class CollectionBlockRecordDto {
  const CollectionBlockRecordDto({
    required this.id,
    required this.collectionId,
    required this.parentBlockId,
    required this.typeKey,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.createdAtIso,
    required this.updatedAtIso,
    required this.imageUrl,
    required this.fileType,
    required this.fileSizeLabel,
    required this.url,
    required this.domainLabel,
    required this.currencyCode,
    required this.amount,
    required this.eventAtIso,
    required this.expiryDateIso,
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

  factory CollectionBlockRecordDto.fromMap(Map<String, dynamic> map) {
    final tagsRaw = map['tags'];
    final metadataRaw = map['metadata'];
    final checklistRaw = map['checklist_items'];

    return CollectionBlockRecordDto(
      id: _asString(map['id']),
      collectionId: _asString(map['collection_id']),
      parentBlockId: _nullableString(map['parent_block_id']),
      typeKey: _asString(map['type_key']),
      title: _asString(map['title']),
      subtitle: _asString(map['subtitle']),
      description: _asString(map['description']),
      createdAtIso: _asString(map['created_at_iso']),
      updatedAtIso: _asString(map['updated_at_iso']),
      imageUrl: _nullableString(map['image_url']),
      fileType: _nullableString(map['file_type']),
      fileSizeLabel: _nullableString(map['file_size_label']),
      url: _nullableString(map['url']),
      domainLabel: _nullableString(map['domain_label']),
      currencyCode: _nullableString(map['currency_code']),
      amount: _nullableDouble(map['amount']),
      eventAtIso: _nullableString(map['event_at_iso']),
      expiryDateIso: _nullableString(map['expiry_date_iso']),
      latitude: _nullableDouble(map['latitude']),
      longitude: _nullableDouble(map['longitude']),
      locationLabel: _nullableString(map['location_label']),
      isCompleted: map['is_completed'] == true,
      statusLabel: _nullableString(map['status_label']),
      tags: tagsRaw is List
          ? tagsRaw
                .map((value) => '$value'.trim())
                .where((v) => v.isNotEmpty)
                .toList(growable: false)
          : const <String>[],
      metadata: metadataRaw is Map
          ? Map<String, String>.fromEntries(
              metadataRaw.entries.map(
                (entry) => MapEntry('${entry.key}', '${entry.value}'),
              ),
            )
          : const <String, String>{},
      checklistItems: checklistRaw is List
          ? checklistRaw
                .whereType<Map>()
                .map(
                  (raw) => CollectionChecklistItemRecordDto.fromMap(
                    Map<String, dynamic>.from(raw),
                  ),
                )
                .toList(growable: false)
          : const <CollectionChecklistItemRecordDto>[],
      position: (map['position'] as int?) ?? 0,
      filePath: _nullableString(map['file_path']),
      repeatInterval: _nullableString(map['repeat_interval']),
    );
  }

  final String id;
  final String collectionId;
  final String? parentBlockId;
  final String typeKey;
  final String title;
  final String subtitle;
  final String description;
  final String createdAtIso;
  final String updatedAtIso;
  final String? imageUrl;
  final String? fileType;
  final String? fileSizeLabel;
  final String? url;
  final String? domainLabel;
  final String? currencyCode;
  final double? amount;
  final String? eventAtIso;
  final String? expiryDateIso;
  final double? latitude;
  final double? longitude;
  final String? locationLabel;
  final bool isCompleted;
  final String? statusLabel;
  final List<String> tags;
  final Map<String, String> metadata;
  final List<CollectionChecklistItemRecordDto> checklistItems;
  final int position;
  final String? filePath;
  final String? repeatInterval;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'collection_id': collectionId,
      'parent_block_id': parentBlockId,
      'type_key': typeKey,
      'title': title,
      'subtitle': subtitle,
      'description': description,
      'created_at_iso': createdAtIso,
      'updated_at_iso': updatedAtIso,
      'image_url': imageUrl,
      'file_type': fileType,
      'file_size_label': fileSizeLabel,
      'url': url,
      'domain_label': domainLabel,
      'currency_code': currencyCode,
      'amount': amount,
      'event_at_iso': eventAtIso,
      'expiry_date_iso': expiryDateIso,
      'latitude': latitude,
      'longitude': longitude,
      'location_label': locationLabel,
      'is_completed': isCompleted,
      'status_label': statusLabel,
      'tags': tags,
      'metadata': metadata,
      'checklist_items': checklistItems
          .map((item) => item.toMap())
          .toList(growable: false),
      'position': position,
      'file_path': filePath,
      'repeat_interval': repeatInterval,
    };
  }
}

class CollectionChecklistItemRecordDto {
  const CollectionChecklistItemRecordDto({
    required this.id,
    required this.title,
    required this.isDone,
  });

  factory CollectionChecklistItemRecordDto.fromMap(Map<String, dynamic> map) {
    return CollectionChecklistItemRecordDto(
      id: _asString(map['id']),
      title: _asString(map['title']),
      isDone: map['is_done'] == true,
    );
  }

  final String id;
  final String title;
  final bool isDone;

  Map<String, dynamic> toMap() {
    return {'id': id, 'title': title, 'is_done': isDone};
  }
}

String _asString(dynamic value) {
  final resolved = '$value'.trim();
  if (resolved.toLowerCase() == 'null') {
    return '';
  }
  return resolved;
}

String? _nullableString(dynamic value) {
  final resolved = _asString(value);
  if (resolved.isEmpty) {
    return null;
  }
  return resolved;
}

double? _nullableDouble(dynamic value) {
  if (value == null) {
    return null;
  }
  if (value is num) {
    return value.toDouble();
  }
  return double.tryParse('$value');
}
