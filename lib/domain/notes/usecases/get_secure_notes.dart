import 'package:pass_doc_manager/domain/notes/entities/secure_note_entity.dart';
import 'package:pass_doc_manager/domain/notes/repositories/secure_notes_repository.dart';

class GetSecureNotes {
  const GetSecureNotes(this._repository);

  final SecureNotesRepository _repository;

  Future<List<SecureNoteSummaryEntity>> call() {
    return _repository.getNotes();
  }
}
