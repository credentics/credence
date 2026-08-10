enum ShareTtl {
  oneHour,
  oneDay,
  sevenDays,
}

enum ShareItemType {
  credential,
  document,
}

class SharePayloadEntity {
  const SharePayloadEntity({
    required this.itemType,
    required this.itemId,
    required this.itemName,
    required this.fields,
    required this.ttl,
    required this.createdAt,
    required this.expiresAt,
  });

  final ShareItemType itemType;
  final String itemId;
  final String itemName;
  final Map<String, String> fields;
  final ShareTtl ttl;
  final DateTime createdAt;
  final DateTime expiresAt;
}
