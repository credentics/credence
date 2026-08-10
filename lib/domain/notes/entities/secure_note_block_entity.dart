class SecureNoteBlockEntity {
  const SecureNoteBlockEntity({
    required this.id,
    required this.noteId,
    required this.type,
    required this.contentJson,
    required this.plainText,
    required this.orderIndex,
    required this.createdAt,
    required this.updatedAt,
    required this.contentHash,
  });

  final String id;
  final String noteId;
  final String type;
  final String contentJson;
  final String plainText;
  final int orderIndex;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String contentHash;

  SecureNoteBlockEntity copyWith({
    String? id,
    String? noteId,
    String? type,
    String? contentJson,
    String? plainText,
    int? orderIndex,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? contentHash,
  }) {
    return SecureNoteBlockEntity(
      id: id ?? this.id,
      noteId: noteId ?? this.noteId,
      type: type ?? this.type,
      contentJson: contentJson ?? this.contentJson,
      plainText: plainText ?? this.plainText,
      orderIndex: orderIndex ?? this.orderIndex,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      contentHash: contentHash ?? this.contentHash,
    );
  }
}
