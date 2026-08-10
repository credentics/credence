import 'package:pass_doc_manager/domain/notes/entities/secure_note_entity.dart';

abstract class SecureNotesRepository {
  Future<void> migrateLegacyNotesIfNeeded();

  Future<List<SecureNoteSummaryEntity>> getNotes();

  Future<SecureNoteDetailEntity> getNoteById(String id);

  Future<SecureNoteDetailEntity> createNote({
    String title = '',
    String preview = '',
  });

  Future<void> saveNoteSnapshot(SecureNoteSnapshotEntity snapshot);

  Future<void> deleteNote(String id);
}
