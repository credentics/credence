import 'package:pass_doc_manager/domain/notes/entities/secure_note_entity.dart';
import 'package:pass_doc_manager/domain/notes/repositories/secure_notes_repository.dart';

class SaveSecureNoteSnapshot {
  const SaveSecureNoteSnapshot(this._repository);

  final SecureNotesRepository _repository;

  Future<void> call(SecureNoteSnapshotEntity snapshot) {
    return _repository.saveNoteSnapshot(snapshot);
  }
}
