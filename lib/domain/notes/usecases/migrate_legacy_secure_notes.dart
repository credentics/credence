import 'package:pass_doc_manager/domain/notes/repositories/secure_notes_repository.dart';

class MigrateLegacySecureNotes {
  const MigrateLegacySecureNotes(this._repository);

  final SecureNotesRepository _repository;

  Future<void> call() {
    return _repository.migrateLegacyNotesIfNeeded();
  }
}
