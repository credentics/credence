import 'dart:async';

import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:pass_doc_manager/app/di/injection.dart';
import 'package:pass_doc_manager/app/theme/app_palette.dart';
import 'package:pass_doc_manager/core/utils/local_asset_file_store.dart';
import 'package:pass_doc_manager/domain/notes/entities/secure_note_block_entity.dart';
import 'package:pass_doc_manager/domain/notes/entities/secure_note_entity.dart';
import 'package:pass_doc_manager/domain/notes/usecases/create_secure_note.dart';
import 'package:pass_doc_manager/domain/notes/usecases/delete_secure_note.dart';
import 'package:pass_doc_manager/domain/notes/usecases/get_secure_note.dart';
import 'package:pass_doc_manager/domain/notes/usecases/save_secure_note_snapshot.dart';
import 'package:pass_doc_manager/features/notes/presentation/support/note_appflowy_document_codec.dart';
import 'package:pass_doc_manager/l10n/l10n.dart';

class NoteEditorPage extends StatefulWidget {
  const NoteEditorPage({super.key, this.noteId});

  final String? noteId;

  @override
  State<NoteEditorPage> createState() => _NoteEditorPageState();
}

class _NoteEditorPageState extends State<NoteEditorPage> {
  final _titleController = TextEditingController();
  final _focusNode = FocusNode();
  final _imagePicker = ImagePicker();

  EditorState? _editorState;
  EditorScrollController? _editorScrollController;
  SecureNoteDetailEntity? _note;
  Map<String, SecureNoteBlockEntity> _previousBlocks = const {};
  StreamSubscription<dynamic>? _editorSubscription;
  Timer? _saveDebounce;
  bool _loading = true;
  bool _saving = false;
  bool _createdInThisSession = false;
  bool _closing = false;
  DateTime? _lastSavedAt;
  String? _errorMessage;

  CreateSecureNote get _createNote => getIt<CreateSecureNote>();
  GetSecureNote get _getNote => getIt<GetSecureNote>();
  SaveSecureNoteSnapshot get _saveSnapshot => getIt<SaveSecureNoteSnapshot>();
  DeleteSecureNote get _deleteNote => getIt<DeleteSecureNote>();

  @override
  void initState() {
    super.initState();
    _titleController.addListener(_scheduleSave);
    unawaited(_load());
  }

  @override
  void dispose() {
    _saveDebounce?.cancel();
    _editorSubscription?.cancel();
    _editorScrollController?.dispose();
    _titleController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final detail = widget.noteId == null
          ? await _createNote()
          : await _getNote(widget.noteId!);
      final editorState = EditorState(
        document: NoteAppFlowyDocumentCodec.documentFromDetail(detail),
      );
      final editorScrollController = EditorScrollController(
        editorState: editorState,
        shrinkWrap: false,
      );
      final editorSubscription = editorState.transactionStream.listen((_) {
        _scheduleSave();
      });

      if (!mounted) {
        await editorSubscription.cancel();
        editorScrollController.dispose();
        return;
      }
      setState(() {
        _note = detail;
        _editorState = editorState;
        _editorScrollController = editorScrollController;
        _editorSubscription = editorSubscription;
        _previousBlocks = {for (final block in detail.blocks) block.id: block};
        _createdInThisSession = widget.noteId == null;
        _titleController.text = detail.title;
        _lastSavedAt = detail.updatedAt;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _errorMessage = '$error';
      });
    }
  }

  void _scheduleSave() {
    if (_loading || _closing || _note == null || _editorState == null) {
      return;
    }
    _saveDebounce?.cancel();
    _saveDebounce = Timer(const Duration(milliseconds: 550), () {
      unawaited(_persistNow());
    });
  }

  Future<void> _persistNow() async {
    final note = _note;
    final editorState = _editorState;
    if (note == null || editorState == null || _closing) {
      return;
    }
    _saveDebounce?.cancel();
    final now = DateTime.now();
    final blocks = NoteAppFlowyDocumentCodec.blocksFromDocument(
      noteId: note.id,
      document: editorState.document,
      now: now,
      previousBlocks: _previousBlocks,
    );
    final title = _resolveTitle(editorState.document);
    final preview = NoteAppFlowyDocumentCodec.previewFromDocument(
      editorState.document,
    );

    if (mounted) {
      setState(() => _saving = true);
    }
    await _saveSnapshot(
      SecureNoteSnapshotEntity(
        id: note.id,
        title: title,
        preview: preview,
        updatedAt: now,
        blocks: blocks,
      ),
    );
    _previousBlocks = {for (final block in blocks) block.id: block};
    _note = SecureNoteDetailEntity(
      id: note.id,
      title: title,
      preview: preview,
      createdAt: note.createdAt,
      updatedAt: now,
      isPinned: note.isPinned,
      blocks: blocks,
    );
    if (mounted) {
      setState(() {
        _saving = false;
        _lastSavedAt = now;
      });
    }
  }

  String _resolveTitle(Document document) {
    final explicit = _titleController.text.trim();
    if (explicit.isNotEmpty) return explicit;
    final derived = NoteAppFlowyDocumentCodec.titleFromDocument(document);
    return derived.isEmpty ? 'Untitled' : derived;
  }

  bool get _isEmptyNewNote {
    final note = _note;
    final editorState = _editorState;
    if (!_createdInThisSession || note == null || editorState == null) {
      return false;
    }
    final hasTitle = _titleController.text.trim().isNotEmpty;
    final body = NoteAppFlowyDocumentCodec.plainTextFromDocument(
      editorState.document,
    );
    return !hasTitle && body.trim().isEmpty;
  }

  Future<void> _close() async {
    if (_closing) return;
    _closing = true;
    FocusManager.instance.primaryFocus?.unfocus();
    if (_isEmptyNewNote && _note != null) {
      await _deleteNote(_note!.id);
    } else {
      await _persistNow();
    }
    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  Future<void> _toggleInline(String key) async {
    await _editorState?.toggleAttribute(key);
    _focusNode.requestFocus();
  }

  Future<void> _formatBlock(String type, {Map<String, Object>? attrs}) async {
    final editorState = _editorState;
    final selection = editorState?.selection;
    if (editorState == null || selection == null) return;
    await editorState.formatNode(
      selection,
      (node) => node.copyWith(
        type: type,
        attributes: {...node.attributes, if (attrs != null) ...attrs},
      ),
    );
    _focusNode.requestFocus();
  }

  Future<void> _insertDivider() async {
    final editorState = _editorState;
    final selection = editorState?.selection;
    if (editorState == null || selection == null) return;
    final node = editorState.getNodeAtPath(selection.end.path);
    if (node == null) return;
    final insertedPath = (node.delta?.isEmpty ?? false)
        ? node.path
        : node.path.next;
    final transaction = editorState.transaction
      ..insertNode(insertedPath, dividerNode())
      ..insertNode(insertedPath.next, paragraphNode())
      ..afterSelection = Selection.collapsed(Position(path: insertedPath.next));
    await editorState.apply(transaction);
    _focusNode.requestFocus();
  }

  Future<void> _insertImage() async {
    final image = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 92,
    );
    if (image == null) return;
    final storedPath = await LocalAssetFileStore.copyIntoAppSupport(
      sourcePath: image.path,
      directoryName: 'secure_notes_assets',
      fileNamePrefix: _resolveTitle(_editorState!.document),
    );
    if (storedPath == null) return;
    await _insertNode(imageNode(url: storedPath));
  }

  Future<void> _insertFile() async {
    final files = await openFiles(
      acceptedTypeGroups: const [
        XTypeGroup(
          label: 'Documents',
          extensions: ['pdf', 'doc', 'docx', 'txt', 'md', 'rtf'],
          mimeTypes: [
            'application/pdf',
            'text/plain',
            'text/markdown',
            'application/msword',
          ],
        ),
      ],
    );
    if (files.isEmpty) return;
    final file = files.first;
    final storedPath = await LocalAssetFileStore.copyIntoAppSupport(
      sourcePath: file.path,
      directoryName: 'secure_notes_assets',
      fileNamePrefix: _resolveTitle(_editorState!.document),
    );
    if (storedPath == null) return;
    final label = p.basename(storedPath);
    await _insertNode(
      paragraphNode(
        text: 'Attachment: $label',
        attributes: {
          NoteAppFlowyDocumentCodec.blockAttachmentPathKey: storedPath,
        },
      ),
    );
  }

  Future<void> _insertNode(Node node) async {
    final editorState = _editorState;
    if (editorState == null) return;
    final selection = editorState.selection;
    if (selection == null) {
      final path = [editorState.document.root.children.length];
      final transaction = editorState.transaction..insertNode(path, node);
      await editorState.apply(transaction);
      return;
    }
    final current = editorState.getNodeAtPath(selection.end.path);
    if (current == null) return;
    final transaction = editorState.transaction;
    if (current.type == ParagraphBlockKeys.type &&
        (current.delta?.isEmpty ?? false)) {
      transaction
        ..insertNode(current.path, node)
        ..deleteNode(current);
    } else {
      transaction.insertNode(current.path.next, node);
    }
    transaction.afterSelection = Selection.collapsed(
      Position(path: current.path.next),
    );
    await editorState.apply(transaction);
    _focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (!didPop) await _close();
      },
      child: Scaffold(
        backgroundColor: _notesPaper,
        resizeToAvoidBottomInset: true,
        body: _loading
            ? Center(child: CircularProgressIndicator(color: palette.primary))
            : _errorMessage != null
            ? _ErrorView(message: _errorMessage!, onBack: _close)
            : _editorBody(palette),
      ),
    );
  }

  Widget _editorBody(AppPalette palette) {
    final editorState = _editorState!;
    final editorScrollController = _editorScrollController!;
    return Stack(
      children: [
        MobileFloatingToolbar(
          editorState: editorState,
          editorScrollController: editorScrollController,
          floatingToolbarHeight: 36,
          toolbarBuilder: (context, anchor, closeToolbar) {
            return AdaptiveTextSelectionToolbar.editable(
              clipboardStatus: ClipboardStatus.pasteable,
              onCopy: () {
                copyCommand.execute(editorState);
                closeToolbar();
              },
              onCut: () {
                cutCommand.execute(editorState);
                closeToolbar();
              },
              onPaste: () {
                pasteCommand.execute(editorState);
                closeToolbar();
              },
              onSelectAll: () {
                selectAllCommand.execute(editorState);
                closeToolbar();
              },
              onLiveTextInput: null,
              onLookUp: null,
              onSearchWeb: null,
              onShare: null,
              anchors: TextSelectionToolbarAnchors(primaryAnchor: anchor),
            );
          },
          child: AppFlowyEditor(
            editorState: editorState,
            editorScrollController: editorScrollController,
            focusNode: _focusNode,
            autoFocus: widget.noteId == null,
            showMagnifier: true,
            blockComponentBuilders: _notesBlockComponentBuilders,
            editorStyle: EditorStyle.mobile(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              cursorColor: _notesInk,
              dragHandleColor: _notesInk,
              selectionColor: _notesInk.withValues(alpha: 0.15),
              textStyleConfiguration: TextStyleConfiguration(
                text: const TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 17,
                  height: 1.26,
                  color: _notesInk,
                  fontWeight: FontWeight.w500,
                ),
                bold: const TextStyle(fontWeight: FontWeight.w800),
                italic: const TextStyle(fontStyle: FontStyle.italic),
                underline: const TextStyle(
                  decoration: TextDecoration.underline,
                ),
                strikethrough: const TextStyle(
                  decoration: TextDecoration.lineThrough,
                ),
                href: TextStyle(
                  color: palette.primary,
                  decoration: TextDecoration.underline,
                ),
                code: TextStyle(
                  color: _notesInk,
                  backgroundColor: _notesChip,
                  fontFamily: 'JetBrains Mono',
                  fontSize: 14,
                ),
                lineHeight: 1.26,
              ),
            ),
            footer: const SizedBox(height: 120),
            header: _EditorHeader(
              titleController: _titleController,
              saving: _saving,
              lastSavedAt: _lastSavedAt,
              onBack: _close,
            ),
          ),
        ),
        _FormattingBar(
          onBold: () => _toggleInline(AppFlowyRichTextKeys.bold),
          onItalic: () => _toggleInline(AppFlowyRichTextKeys.italic),
          onUnderline: () => _toggleInline(AppFlowyRichTextKeys.underline),
          onParagraph: () => _formatBlock(ParagraphBlockKeys.type),
          onHeading: () => _formatBlock(
            HeadingBlockKeys.type,
            attrs: {HeadingBlockKeys.level: 1},
          ),
          onChecklist: () => _formatBlock(
            TodoListBlockKeys.type,
            attrs: {TodoListBlockKeys.checked: false},
          ),
          onBullet: () => _formatBlock(BulletedListBlockKeys.type),
          onNumbered: () => _formatBlock(NumberedListBlockKeys.type),
          onQuote: () => _formatBlock(QuoteBlockKeys.type),
          onDivider: _insertDivider,
          onImage: _insertImage,
          onFile: _insertFile,
        ),
      ],
    );
  }
}

class _EditorHeader extends StatelessWidget {
  const _EditorHeader({
    required this.titleController,
    required this.saving,
    required this.lastSavedAt,
    required this.onBack,
  });

  final TextEditingController titleController;
  final bool saving;
  final DateTime? lastSavedAt;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _RoundIconButton(
                  icon: Icons.chevron_left_rounded,
                  onPressed: onBack,
                ),
                const Spacer(),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  child: Text(
                    saving ? 'Saving...' : _savedLabel(context),
                    key: ValueKey(saving),
                    style: const TextStyle(
                      fontFamily: 'JetBrains Mono',
                      fontSize: 12,
                      letterSpacing: 1.8,
                      color: _notesMuted,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),
            TextField(
              controller: titleController,
              maxLines: null,
              textCapitalization: TextCapitalization.sentences,
              style: const TextStyle(
                fontFamily: 'Manrope',
                fontSize: 34,
                height: 1.05,
                letterSpacing: -1.0,
                fontWeight: FontWeight.w800,
                color: _notesInk,
              ),
              decoration: const InputDecoration(
                hintText: 'Title',
                hintStyle: TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 34,
                  height: 1.05,
                  letterSpacing: -1.0,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFFB8B1A8),
                ),
                border: InputBorder.none,
                isCollapsed: true,
              ),
            ),
            const SizedBox(height: 10),
            Container(height: 1, color: const Color(0xFFE8E1D8)),
            const SizedBox(height: 18),
          ],
        ),
      ),
    );
  }

  String _savedLabel(BuildContext context) {
    if (lastSavedAt == null) return 'LOCAL NOTE';
    final now = DateTime.now();
    final isToday =
        now.year == lastSavedAt!.year &&
        now.month == lastSavedAt!.month &&
        now.day == lastSavedAt!.day;
    if (isToday) return 'SAVED TODAY';
    return 'SAVED LOCALLY';
  }
}

class _FormattingBar extends StatelessWidget {
  const _FormattingBar({
    required this.onBold,
    required this.onItalic,
    required this.onUnderline,
    required this.onParagraph,
    required this.onHeading,
    required this.onChecklist,
    required this.onBullet,
    required this.onNumbered,
    required this.onQuote,
    required this.onDivider,
    required this.onImage,
    required this.onFile,
  });

  final VoidCallback onBold;
  final VoidCallback onItalic;
  final VoidCallback onUnderline;
  final VoidCallback onParagraph;
  final VoidCallback onHeading;
  final VoidCallback onChecklist;
  final VoidCallback onBullet;
  final VoidCallback onNumbered;
  final VoidCallback onQuote;
  final VoidCallback onDivider;
  final VoidCallback onImage;
  final VoidCallback onFile;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    return Positioned(
      left: 0,
      right: 0,
      bottom: bottom,
      child: SafeArea(
        top: false,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          margin: const EdgeInsets.fromLTRB(14, 0, 14, 10),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.94),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE3DDD4)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _ToolButton(label: 'Aa', onTap: onParagraph),
                _ToolButton(label: 'H1', onTap: onHeading),
                _ToolButton(label: 'B', onTap: onBold),
                _ToolButton(label: 'I', onTap: onItalic),
                _ToolButton(label: 'U', onTap: onUnderline),
                _ToolIcon(icon: Icons.checklist_rounded, onTap: onChecklist),
                _ToolIcon(
                  icon: Icons.format_list_bulleted_rounded,
                  onTap: onBullet,
                ),
                _ToolIcon(
                  icon: Icons.format_list_numbered_rounded,
                  onTap: onNumbered,
                ),
                _ToolIcon(icon: Icons.format_quote_rounded, onTap: onQuote),
                _ToolIcon(
                  icon: Icons.horizontal_rule_rounded,
                  onTap: onDivider,
                ),
                _ToolIcon(icon: Icons.image_outlined, onTap: onImage),
                _ToolIcon(icon: Icons.attach_file_rounded, onTap: onFile),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ToolButton extends StatelessWidget {
  const _ToolButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: Material(
        color: _notesChip,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            height: 38,
            width: 44,
            child: Center(
              child: Text(
                label,
                style: const TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: _notesInk,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ToolIcon extends StatelessWidget {
  const _ToolIcon({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: Material(
        color: _notesChip,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            height: 38,
            width: 42,
            child: Icon(icon, size: 20, color: _notesInk),
          ),
        ),
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({required this.icon, required this.onPressed});

  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF1EEE8),
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(22),
        child: SizedBox(
          width: 48,
          height: 48,
          child: Icon(icon, color: _notesInk, size: 30),
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onBack});

  final String message;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _RoundIconButton(
              icon: Icons.chevron_left_rounded,
              onPressed: onBack,
            ),
            const Spacer(),
            Text(
              context.l10n.commonErrorGeneric,
              style: const TextStyle(
                fontFamily: 'Manrope',
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: _notesInk,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              message,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: _notesMuted,
              ),
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}

const _notesPaper = Color(0xFFFBFAF6);
const _notesInk = Color(0xFF211E19);
const _notesMuted = Color(0xFF928A80);
const _notesChip = Color(0xFFF1EEE8);

final Map<String, BlockComponentBuilder> _notesBlockComponentBuilders = {
  ...standardBlockComponentBuilderMap,
  ParagraphBlockKeys.type: ParagraphBlockComponentBuilder(
    configuration: _notesCompactBlockConfiguration(
      placeholderText: (_) => ' ',
      padding: (_) => const EdgeInsets.symmetric(vertical: 1),
    ),
  ),
  TodoListBlockKeys.type: TodoListBlockComponentBuilder(
    configuration: _notesCompactBlockConfiguration(
      placeholderText: (_) => AppFlowyEditorL10n.current.toDoPlaceholder,
      padding: (_) => const EdgeInsets.symmetric(vertical: 1),
    ),
    toggleChildrenTriggers: const [
      LogicalKeyboardKey.shift,
      LogicalKeyboardKey.shiftLeft,
      LogicalKeyboardKey.shiftRight,
    ],
  ),
  BulletedListBlockKeys.type: BulletedListBlockComponentBuilder(
    configuration: _notesCompactBlockConfiguration(
      placeholderText: (_) => AppFlowyEditorL10n.current.listItemPlaceholder,
      padding: (_) => const EdgeInsets.symmetric(vertical: 1),
    ),
  ),
  NumberedListBlockKeys.type: NumberedListBlockComponentBuilder(
    configuration: _notesCompactBlockConfiguration(
      placeholderText: (_) => AppFlowyEditorL10n.current.listItemPlaceholder,
      padding: (_) => const EdgeInsets.symmetric(vertical: 1),
    ),
  ),
  QuoteBlockKeys.type: QuoteBlockComponentBuilder(
    configuration: _notesCompactBlockConfiguration(
      placeholderText: (_) => AppFlowyEditorL10n.current.quote,
      padding: (_) => const EdgeInsets.symmetric(vertical: 2),
    ),
  ),
  HeadingBlockKeys.type: HeadingBlockComponentBuilder(
    configuration: _notesCompactBlockConfiguration(
      placeholderText: (node) =>
          'Heading ${node.attributes[HeadingBlockKeys.level]}',
      padding: (_) => const EdgeInsets.only(top: 8, bottom: 2),
    ),
  ),
  DividerBlockKeys.type: DividerBlockComponentBuilder(
    configuration: _notesCompactBlockConfiguration(
      padding: (_) => const EdgeInsets.symmetric(vertical: 6),
    ),
    lineColor: const Color(0xFFE4DED5),
    height: 8,
  ),
};

BlockComponentConfiguration _notesCompactBlockConfiguration({
  String Function(Node node)? placeholderText,
  EdgeInsets Function(Node node)? padding,
}) {
  return BlockComponentConfiguration(
    padding: padding ?? (_) => EdgeInsets.zero,
    placeholderText: placeholderText ?? (_) => ' ',
    placeholderTextStyle: (_, {textSpan}) => const TextStyle(
      fontFamily: 'Manrope',
      fontSize: 17,
      height: 1.26,
      color: Color(0xFFB8B1A8),
      fontWeight: FontWeight.w500,
    ),
  );
}
