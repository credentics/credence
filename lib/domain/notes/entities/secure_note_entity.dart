import 'package:pass_doc_manager/domain/notes/entities/secure_note_block_entity.dart';

class SecureNoteSummaryEntity {
  const SecureNoteSummaryEntity({
    required this.id,
    required this.title,
    required this.preview,
    required this.blockCount,
    required this.createdAt,
    required this.updatedAt,
    required this.isPinned,
  });

  final String id;
  final String title;
  final String preview;
  final int blockCount;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isPinned;
}

class SecureNoteDetailEntity {
  const SecureNoteDetailEntity({
    required this.id,
    required this.title,
    required this.preview,
    required this.createdAt,
    required this.updatedAt,
    required this.isPinned,
    required this.blocks,
  });

  final String id;
  final String title;
  final String preview;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isPinned;
  final List<SecureNoteBlockEntity> blocks;
}

class SecureNoteSnapshotEntity {
  const SecureNoteSnapshotEntity({
    required this.id,
    required this.title,
    required this.preview,
    required this.updatedAt,
    required this.blocks,
  });

  final String id;
  final String title;
  final String preview;
  final DateTime updatedAt;
  final List<SecureNoteBlockEntity> blocks;
}
