import 'package:pass_doc_manager/domain/notes/entities/secure_note_entity.dart';

enum SecureNotesStatus { initial, loading, ready, failure }

class SecureNotesState {
  const SecureNotesState({
    required this.status,
    required this.notes,
    required this.query,
    this.errorMessage,
  });

  const SecureNotesState.initial()
    : status = SecureNotesStatus.initial,
      notes = const <SecureNoteSummaryEntity>[],
      query = '',
      errorMessage = null;

  final SecureNotesStatus status;
  final List<SecureNoteSummaryEntity> notes;
  final String query;
  final String? errorMessage;

  List<SecureNoteSummaryEntity> get visibleNotes {
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) return notes;
    return notes
        .where((note) {
          return note.title.toLowerCase().contains(normalized) ||
              note.preview.toLowerCase().contains(normalized);
        })
        .toList(growable: false);
  }

  SecureNotesState copyWith({
    SecureNotesStatus? status,
    List<SecureNoteSummaryEntity>? notes,
    String? query,
    String? errorMessage,
    bool clearError = false,
  }) {
    return SecureNotesState(
      status: status ?? this.status,
      notes: notes ?? this.notes,
      query: query ?? this.query,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}
