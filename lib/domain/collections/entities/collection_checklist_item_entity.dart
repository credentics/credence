class CollectionChecklistItemEntity {
  const CollectionChecklistItemEntity({
    required this.id,
    required this.title,
    required this.isDone,
  });

  final String id;
  final String title;
  final bool isDone;

  CollectionChecklistItemEntity copyWith({
    String? id,
    String? title,
    bool? isDone,
  }) {
    return CollectionChecklistItemEntity(
      id: id ?? this.id,
      title: title ?? this.title,
      isDone: isDone ?? this.isDone,
    );
  }
}
