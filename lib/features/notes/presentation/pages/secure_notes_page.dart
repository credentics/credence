import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:pass_doc_manager/app/di/injection.dart';
import 'package:pass_doc_manager/domain/notes/entities/secure_note_entity.dart';
import 'package:pass_doc_manager/domain/notes/usecases/delete_secure_note.dart';
import 'package:pass_doc_manager/domain/notes/usecases/get_secure_notes.dart';
import 'package:pass_doc_manager/domain/notes/usecases/migrate_legacy_secure_notes.dart';
import 'package:pass_doc_manager/features/notes/presentation/cubit/secure_notes_cubit.dart';
import 'package:pass_doc_manager/features/notes/presentation/cubit/secure_notes_state.dart';
import 'package:pass_doc_manager/features/notes/presentation/pages/note_editor_page.dart';
import 'package:pass_doc_manager/l10n/l10n.dart';

class SecureNotesPage extends StatefulWidget {
  const SecureNotesPage({super.key});

  @override
  State<SecureNotesPage> createState() => _SecureNotesPageState();
}

class _SecureNotesPageState extends State<SecureNotesPage> {
  late final SecureNotesCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = SecureNotesCubit(
      getSecureNotes: getIt<GetSecureNotes>(),
      deleteSecureNote: getIt<DeleteSecureNote>(),
      migrateLegacySecureNotes: getIt<MigrateLegacySecureNotes>(),
    )..load();
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  Future<void> _openEditor({String? noteId}) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => NoteEditorPage(noteId: noteId)),
    );
    if (changed == true) {
      await _cubit.load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: Scaffold(
        backgroundColor: _notesPaper,
        body: SafeArea(
          bottom: false,
          child: BlocBuilder<SecureNotesCubit, SecureNotesState>(
            builder: (context, state) {
              return CustomScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                slivers: [
                  SliverToBoxAdapter(
                    child: _NotesHeader(
                      count: state.notes.length,
                      onBack: () => Navigator.of(context).maybePop(),
                      onAdd: () => _openEditor(),
                      onSearchChanged: _cubit.updateQuery,
                    ),
                  ),
                  if (state.status == SecureNotesStatus.loading)
                    const SliverFillRemaining(
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (state.status == SecureNotesStatus.failure)
                    SliverFillRemaining(
                      child: _NotesMessage(
                        title: context.l10n.commonErrorGeneric,
                        subtitle: state.errorMessage ?? '',
                        icon: Icons.warning_amber_rounded,
                      ),
                    )
                  else if (state.visibleNotes.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: _NotesMessage(
                        title: context.l10n.secureNotesEmpty,
                        subtitle:
                            'Create private notes, checklists, drafts, and attachments. Everything stays on this device.',
                        icon: Icons.sticky_note_2_outlined,
                      ),
                    )
                  else
                    _NotesList(
                      notes: state.visibleNotes,
                      onOpen: (note) => _openEditor(noteId: note.id),
                      onDelete: _cubit.delete,
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _NotesHeader extends StatelessWidget {
  const _NotesHeader({
    required this.count,
    required this.onBack,
    required this.onAdd,
    required this.onSearchChanged,
  });

  final int count;
  final VoidCallback onBack;
  final VoidCallback onAdd;
  final ValueChanged<String> onSearchChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 8, 22, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _RoundButton(icon: Icons.chevron_left_rounded, onTap: onBack),
              const Spacer(),
              _RoundButton(icon: Icons.add_rounded, onTap: onAdd),
            ],
          ),
          const SizedBox(height: 32),
          Text(
            '$count NOTES · LOCAL ONLY',
            style: const TextStyle(
              fontFamily: 'JetBrains Mono',
              fontSize: 13,
              letterSpacing: 4.2,
              fontWeight: FontWeight.w500,
              color: _notesMuted,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            context.l10n.secureNotesTitle,
            style: const TextStyle(
              fontFamily: 'Manrope',
              fontSize: 44,
              height: 1,
              letterSpacing: -1.4,
              fontWeight: FontWeight.w800,
              color: _notesInk,
            ),
          ),
          const SizedBox(height: 24),
          TextField(
            onChanged: onSearchChanged,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: _notesInk,
            ),
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search_rounded, color: _notesMuted),
              hintText: 'Search notes',
              hintStyle: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Color(0xFFB5AEA6),
              ),
              filled: true,
              fillColor: const Color(0xFFF1EEE8),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 15,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NotesList extends StatelessWidget {
  const _NotesList({
    required this.notes,
    required this.onOpen,
    required this.onDelete,
  });

  final List<SecureNoteSummaryEntity> notes;
  final ValueChanged<SecureNoteSummaryEntity> onOpen;
  final ValueChanged<String> onDelete;

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(22, 0, 22, 110),
      sliver: SliverToBoxAdapter(
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: const Color(0xFFE5DED5)),
          ),
          child: Column(
            children: [
              for (var i = 0; i < notes.length; i++) ...[
                _NoteRow(
                  note: notes[i],
                  onTap: () => onOpen(notes[i]),
                  onDelete: () => onDelete(notes[i].id),
                ),
                if (i != notes.length - 1)
                  const Padding(
                    padding: EdgeInsets.only(left: 86),
                    child: Divider(height: 1, color: Color(0xFFEAE5DD)),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _NoteRow extends StatelessWidget {
  const _NoteRow({
    required this.note,
    required this.onTap,
    required this.onDelete,
  });

  final SecureNoteSummaryEntity note;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final date = DateFormat.MMMd().format(note.updatedAt);
    return Dismissible(
      key: ValueKey(note.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        onDelete();
        return false;
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 22),
        decoration: BoxDecoration(
          color: const Color(0xFFE5484D).withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(28),
        ),
        child: const Icon(
          Icons.delete_outline_rounded,
          color: Color(0xFFE5484D),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 14, 18),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF2CC),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.notes_rounded,
                    color: Color(0xFFC48A00),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        note.title.isEmpty ? 'Untitled' : note.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Manrope',
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: _notesInk,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        _subtitle(date),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Manrope',
                          fontSize: 14.5,
                          fontWeight: FontWeight.w500,
                          color: _notesMuted,
                          height: 1.25,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: _notesMuted,
                  size: 26,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _subtitle(String date) {
    final preview = note.preview.trim();
    if (preview.isEmpty) {
      return '$date · ${note.blockCount} blocks';
    }
    return '$date · $preview';
  }
}

class _NotesMessage extends StatelessWidget {
  const _NotesMessage({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 34),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: const Color(0xFFF1EEE8),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(icon, color: _notesMuted, size: 34),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Manrope',
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: _notesInk,
              ),
            ),
            if (subtitle.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: _notesMuted,
                  height: 1.35,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF1EEE8),
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: SizedBox(
          width: 56,
          height: 56,
          child: Icon(icon, color: _notesInk, size: 30),
        ),
      ),
    );
  }
}

const _notesPaper = Color(0xFFFBFAF6);
const _notesInk = Color(0xFF211E19);
const _notesMuted = Color(0xFF928A80);
