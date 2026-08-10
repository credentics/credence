import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pass_doc_manager/domain/notes/usecases/delete_secure_note.dart';
import 'package:pass_doc_manager/domain/notes/usecases/get_secure_notes.dart';
import 'package:pass_doc_manager/domain/notes/usecases/migrate_legacy_secure_notes.dart';
import 'package:pass_doc_manager/features/notes/presentation/cubit/secure_notes_state.dart';

class SecureNotesCubit extends Cubit<SecureNotesState> {
  SecureNotesCubit({
    required GetSecureNotes getSecureNotes,
    required DeleteSecureNote deleteSecureNote,
    required MigrateLegacySecureNotes migrateLegacySecureNotes,
  }) : _getSecureNotes = getSecureNotes,
       _deleteSecureNote = deleteSecureNote,
       _migrateLegacySecureNotes = migrateLegacySecureNotes,
       super(const SecureNotesState.initial());

  final GetSecureNotes _getSecureNotes;
  final DeleteSecureNote _deleteSecureNote;
  final MigrateLegacySecureNotes _migrateLegacySecureNotes;

  Future<void> load() async {
    emit(state.copyWith(status: SecureNotesStatus.loading, clearError: true));
    try {
      await _migrateLegacySecureNotes();
      final notes = await _getSecureNotes();
      emit(state.copyWith(status: SecureNotesStatus.ready, notes: notes));
    } catch (e) {
      emit(
        state.copyWith(status: SecureNotesStatus.failure, errorMessage: '$e'),
      );
    }
  }

  void updateQuery(String query) {
    emit(state.copyWith(query: query));
  }

  Future<void> delete(String noteId) async {
    await _deleteSecureNote(noteId);
    await load();
  }
}
