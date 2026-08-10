import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pass_doc_manager/app/presentation/widgets/generic_app_bar.dart';
import 'package:pass_doc_manager/app/theme/app_palette.dart';
import 'package:pass_doc_manager/data/collections/dtos/collection_record_dto.dart';
import 'package:pass_doc_manager/features/notes/presentation/pages/note_editor_page.dart';
import 'package:pass_doc_manager/features/notes/presentation/support/note_markdown_support.dart';
import 'package:pass_doc_manager/features/notes/presentation/widgets/note_markdown_view.dart';
import 'package:pass_doc_manager/l10n/l10n.dart';

class NoteDetailPage extends StatefulWidget {
  const NoteDetailPage({required this.note, super.key});

  final CollectionBlockRecordDto note;

  @override
  State<NoteDetailPage> createState() => _NoteDetailPageState();
}

class _NoteDetailPageState extends State<NoteDetailPage> {
  Future<void> _openEditor() async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => NoteEditorPage(noteId: widget.note.id)),
    );
    if (!mounted || saved != true) {
      return;
    }
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    final note = widget.note;
    final markdown = NoteMarkdownSupport.markdownFromBlock(note);
    final updatedAt = DateTime.tryParse(note.updatedAtIso);
    final dateLabel = updatedAt == null
        ? ''
        : DateFormat.yMMMMd().add_jm().format(updatedAt);

    return Scaffold(
      backgroundColor: palette.background,
      appBar: GenericAppBar(
        showBackButton: true,
        onBackPressed: () => Navigator.of(context).maybePop(),
        centerTitle: false,
        title: note.title.isEmpty ? context.l10n.noteEditorTitle : note.title,
        titleSpacing: 16,
        actions: [
          TextButton(
            onPressed: _openEditor,
            child: Text(
              context.l10n.commonEdit,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: palette.primary,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        top: false,
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 36),
          children: [
            Text(
              note.title.isEmpty ? 'Untitled' : note.title,
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w800,
                color: palette.textPrimary,
                height: 1.08,
                letterSpacing: -0.9,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                if (dateLabel.isNotEmpty)
                  _NoteMetaChip(icon: Icons.schedule_rounded, label: dateLabel),
              ],
            ),
            const SizedBox(height: 22),
            Container(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 6),
              decoration: BoxDecoration(
                color: palette.surface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: palette.stroke),
                boxShadow: [
                  BoxShadow(
                    color: palette.shadow,
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: NoteMarkdownView(
                markdown: markdown,
                emptyLabel: context.l10n.noteEditorContentHint,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NoteMetaChip extends StatelessWidget {
  const _NoteMetaChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: palette.surfaceSoft,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: palette.stroke),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: palette.textSecondary),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: palette.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
