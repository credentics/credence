import 'package:pass_doc_manager/domain/notes/entities/secure_note_entity.dart';
import 'package:pass_doc_manager/domain/notes/repositories/secure_notes_repository.dart';

class CreateSecureNote {
  const CreateSecureNote(this._repository);

  final SecureNotesRepository _repository;

  Future<SecureNoteDetailEntity> call({
    String title = '',
    String preview = '',
  }) {
    return _repository.createNote(title: title, preview: preview);
  }
}
