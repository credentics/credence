class QuickAccessGroupEntity {
  const QuickAccessGroupEntity({
    required this.categoryKey,
    required this.categoryLabel,
    required this.items,
  });

  final String categoryKey;
  final String categoryLabel;
  final List<QuickAccessItemEntity> items;
}

class QuickAccessItemEntity {
  const QuickAccessItemEntity({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.sourceType,
    required this.sourceId,
    this.logoPath,
    this.iconKey,
    this.dateLabel,
    this.children = const <QuickAccessItemEntity>[],
  });

  final String id;
  final String title;
  final String subtitle;

  /// `credential` | `document` | `collection` | `aggregate`.
  /// Aggregate rows never navigate directly — they expand/collapse children.
  final String sourceType;

  /// For aggregate rows this is the bucket key; for leaf rows it is the
  /// underlying entity id.
  final String sourceId;

  final String? logoPath;

  /// Semantic icon key (see `DocumentIconKey` + the `credential` / `collection`
  /// sentinels). The widget layer maps it to a glyph + accent colour.
  final String? iconKey;

  /// Optional short label shown after the subtitle (e.g. "Oct 2025").
  final String? dateLabel;

  /// Non-empty when this is an aggregate parent row. Children render
  /// inline under the parent when the row is expanded.
  final List<QuickAccessItemEntity> children;

  bool get isAggregate => children.isNotEmpty;
}
