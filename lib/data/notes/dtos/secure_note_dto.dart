import 'package:pass_doc_manager/domain/notes/entities/secure_note_block_entity.dart';
import 'package:pass_doc_manager/domain/notes/entities/secure_note_entity.dart';

class SecureNoteRecordDto {
  const SecureNoteRecordDto({
    required this.id,
    required this.title,
    required this.preview,
    required this.createdAtIso,
    required this.updatedAtIso,
    required this.isPinned,
    required this.isDeleted,
    required this.blockCount,
  });

  factory SecureNoteRecordDto.fromMap(Map<String, Object?> map) {
    return SecureNoteRecordDto(
      id: _asString(map['id']),
      title: _asString(map['title']),
      preview: _asString(map['preview']),
      createdAtIso: _asString(map['created_at_iso']),
      updatedAtIso: _asString(map['updated_at_iso']),
      isPinned: map['is_pinned'] == 1,
      isDeleted: map['is_deleted'] == 1,
      blockCount: _asInt(map['block_count']),
    );
  }

  final String id;
  final String title;
  final String preview;
  final String createdAtIso;
  final String updatedAtIso;
  final bool isPinned;
  final bool isDeleted;
  final int blockCount;

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'title': title,
      'preview': preview,
      'created_at_iso': createdAtIso,
      'updated_at_iso': updatedAtIso,
      'is_pinned': isPinned ? 1 : 0,
      'is_deleted': isDeleted ? 1 : 0,
      'block_count': blockCount,
    };
  }

  SecureNoteSummaryEntity toSummaryEntity() {
    return SecureNoteSummaryEntity(
      id: id,
      title: title,
      preview: preview,
      blockCount: blockCount,
      createdAt: _parseDate(createdAtIso),
      updatedAt: _parseDate(updatedAtIso),
      isPinned: isPinned,
    );
  }
}

class SecureNoteBlockRecordDto {
  const SecureNoteBlockRecordDto({
    required this.id,
    required this.noteId,
    required this.type,
    required this.contentJson,
    required this.plainText,
    required this.orderIndex,
    required this.createdAtIso,
    required this.updatedAtIso,
    required this.contentHash,
  });

  factory SecureNoteBlockRecordDto.fromMap(Map<String, Object?> map) {
    return SecureNoteBlockRecordDto(
      id: _asString(map['id']),
      noteId: _asString(map['note_id']),
      type: _asString(map['type']),
      contentJson: _asString(map['content_json']),
      plainText: _asString(map['plain_text']),
      orderIndex: _asInt(map['order_index']),
      createdAtIso: _asString(map['created_at_iso']),
      updatedAtIso: _asString(map['updated_at_iso']),
      contentHash: _asString(map['content_hash']),
    );
  }

  factory SecureNoteBlockRecordDto.fromEntity(SecureNoteBlockEntity entity) {
    return SecureNoteBlockRecordDto(
      id: entity.id,
      noteId: entity.noteId,
      type: entity.type,
      contentJson: entity.contentJson,
      plainText: entity.plainText,
      orderIndex: entity.orderIndex,
      createdAtIso: entity.createdAt.toIso8601String(),
      updatedAtIso: entity.updatedAt.toIso8601String(),
      contentHash: entity.contentHash,
    );
  }

  final String id;
  final String noteId;
  final String type;
  final String contentJson;
  final String plainText;
  final int orderIndex;
  final String createdAtIso;
  final String updatedAtIso;
  final String contentHash;

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'note_id': noteId,
      'type': type,
      'content_json': contentJson,
      'plain_text': plainText,
      'order_index': orderIndex,
      'created_at_iso': createdAtIso,
      'updated_at_iso': updatedAtIso,
      'content_hash': contentHash,
    };
  }

  SecureNoteBlockEntity toEntity() {
    return SecureNoteBlockEntity(
      id: id,
      noteId: noteId,
      type: type,
      contentJson: contentJson,
      plainText: plainText,
      orderIndex: orderIndex,
      createdAt: _parseDate(createdAtIso),
      updatedAt: _parseDate(updatedAtIso),
      contentHash: contentHash,
    );
  }
}

class SecureNoteDetailDto {
  const SecureNoteDetailDto({required this.note, required this.blocks});

  final SecureNoteRecordDto note;
  final List<SecureNoteBlockRecordDto> blocks;

  Map<String, Object?> toMap() {
    return {
      'note': note.toMap(),
      'blocks': blocks.map((block) => block.toMap()).toList(growable: false),
    };
  }

  SecureNoteDetailEntity toEntity() {
    return SecureNoteDetailEntity(
      id: note.id,
      title: note.title,
      preview: note.preview,
      createdAt: _parseDate(note.createdAtIso),
      updatedAt: _parseDate(note.updatedAtIso),
      isPinned: note.isPinned,
      blocks: blocks.map((block) => block.toEntity()).toList(growable: false),
    );
  }
}

String _asString(Object? value) {
  if (value == null) return '';
  return '$value';
}

int _asInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse('$value') ?? 0;
}

DateTime _parseDate(String value) {
  return DateTime.tryParse(value) ?? DateTime.fromMillisecondsSinceEpoch(0);
}
