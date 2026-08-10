enum ReminderSourceType { document, credential, collection }

enum ReminderAction { uploadNow, viewDetails, renew, resolve }

class SmartReminderEntity {
  const SmartReminderEntity({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.categoryKey,
    required this.sourceType,
    required this.sourceId,
    required this.action,
    this.relevantAt,
    this.isDismissed = false,
  });

  final String id;
  final String title;
  final String subtitle;
  final String categoryKey;
  final ReminderSourceType sourceType;
  final String sourceId;
  final ReminderAction action;
  final DateTime? relevantAt;
  final bool isDismissed;

  SmartReminderEntity copyWith({bool? isDismissed}) => SmartReminderEntity(
    id: id,
    title: title,
    subtitle: subtitle,
    categoryKey: categoryKey,
    sourceType: sourceType,
    sourceId: sourceId,
    action: action,
    relevantAt: relevantAt,
    isDismissed: isDismissed ?? this.isDismissed,
  );
}
