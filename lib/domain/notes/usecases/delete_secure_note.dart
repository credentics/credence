import 'package:pass_doc_manager/domain/notes/repositories/secure_notes_repository.dart';

class DeleteSecureNote {
  const DeleteSecureNote(this._repository);

  final SecureNotesRepository _repository;

  Future<void> call(String id) {
    return _repository.deleteNote(id);
  }
}
