import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:pass_doc_manager/app/theme/app_palette.dart';
import 'package:pass_doc_manager/core/utils/local_asset_file_store.dart';
import 'package:pass_doc_manager/features/notes/presentation/support/note_appflowy_document_codec.dart';

class NoteAppFlowyInlineEditor extends StatefulWidget {
  const NoteAppFlowyInlineEditor({
    super.key,
    required this.editorState,
    required this.focusNode,
    required this.assetDirectoryName,
    required this.fileNamePrefix,
    this.minHeight = 420,
    this.autoFocus = false,
    this.borderless = false,
  });

  final EditorState editorState;
  final FocusNode focusNode;
  final String assetDirectoryName;
  final String fileNamePrefix;
  final double minHeight;
  final bool autoFocus;
  final bool borderless;

  @override
  State<NoteAppFlowyInlineEditor> createState() =>
      _NoteAppFlowyInlineEditorState();
}

class _NoteAppFlowyInlineEditorState extends State<NoteAppFlowyInlineEditor> {
  final _imagePicker = ImagePicker();
  late EditorScrollController _editorScrollController;

  @override
  void initState() {
    super.initState();
    _editorScrollController = EditorScrollController(
      editorState: widget.editorState,
      shrinkWrap: false,
    );
  }

  @override
  void didUpdateWidget(covariant NoteAppFlowyInlineEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.editorState == widget.editorState) return;
    _editorScrollController.dispose();
    _editorScrollController = EditorScrollController(
      editorState: widget.editorState,
      shrinkWrap: false,
    );
  }

  @override
  void dispose() {
    _editorScrollController.dispose();
    super.dispose();
  }

  Future<void> _toggleInline(String key) async {
    await widget.editorState.toggleAttribute(key);
    widget.focusNode.requestFocus();
  }

  Future<void> _formatBlock(String type, {Map<String, Object>? attrs}) async {
    final selection = widget.editorState.selection;
    if (selection == null) return;
    await widget.editorState.formatNode(
      selection,
      (node) => node.copyWith(
        type: type,
        attributes: {...node.attributes, if (attrs != null) ...attrs},
      ),
    );
    widget.focusNode.requestFocus();
  }

  Future<void> _insertDivider() async {
    final selection = widget.editorState.selection;
    if (selection == null) return;
    final node = widget.editorState.getNodeAtPath(selection.end.path);
    if (node == null) return;
    final insertedPath = (node.delta?.isEmpty ?? false)
        ? node.path
        : node.path.next;
    final transaction = widget.editorState.transaction
      ..insertNode(insertedPath, dividerNode())
      ..insertNode(insertedPath.next, paragraphNode())
      ..afterSelection = Selection.collapsed(Position(path: insertedPath.next));
    await widget.editorState.apply(transaction);
    widget.focusNode.requestFocus();
  }

  Future<void> _insertImage() async {
    final image = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 92,
    );
    if (image == null) return;
    final storedPath = await LocalAssetFileStore.copyIntoAppSupport(
      sourcePath: image.path,
      directoryName: widget.assetDirectoryName,
      fileNamePrefix: widget.fileNamePrefix,
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
      directoryName: widget.assetDirectoryName,
      fileNamePrefix: widget.fileNamePrefix,
    );
    if (storedPath == null) return;
    await _insertNode(
      paragraphNode(
        text: 'Attachment: ${p.basename(storedPath)}',
        attributes: {
          NoteAppFlowyDocumentCodec.blockAttachmentPathKey: storedPath,
        },
      ),
    );
  }

  Future<void> _insertNode(Node node) async {
    final selection = widget.editorState.selection;
    if (selection == null) {
      final path = [widget.editorState.document.root.children.length];
      final transaction = widget.editorState.transaction
        ..insertNode(path, node);
      await widget.editorState.apply(transaction);
      return;
    }
    final current = widget.editorState.getNodeAtPath(selection.end.path);
    if (current == null) return;
    final transaction = widget.editorState.transaction;
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
    await widget.editorState.apply(transaction);
    widget.focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          constraints: BoxConstraints(minHeight: widget.minHeight),
          decoration: widget.borderless
              ? null
              : BoxDecoration(
                  color: noteEditorPaper,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: const Color(0xFFE8E1D8)),
                ),
          clipBehavior: widget.borderless ? Clip.none : Clip.antiAlias,
          child: SizedBox(
            height: widget.minHeight,
            child: MobileFloatingToolbar(
              editorState: widget.editorState,
              editorScrollController: _editorScrollController,
              floatingToolbarHeight: 36,
              toolbarBuilder: (context, anchor, closeToolbar) {
                return AdaptiveTextSelectionToolbar.editable(
                  clipboardStatus: ClipboardStatus.pasteable,
                  onCopy: () {
                    copyCommand.execute(widget.editorState);
                    closeToolbar();
                  },
                  onCut: () {
                    cutCommand.execute(widget.editorState);
                    closeToolbar();
                  },
                  onPaste: () {
                    pasteCommand.execute(widget.editorState);
                    closeToolbar();
                  },
                  onSelectAll: () {
                    selectAllCommand.execute(widget.editorState);
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
                editorState: widget.editorState,
                editorScrollController: _editorScrollController,
                focusNode: widget.focusNode,
                autoFocus: widget.autoFocus,
                showMagnifier: true,
                blockComponentBuilders: noteEditorBlockComponentBuilders,
                editorStyle: EditorStyle.mobile(
                  padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
                  cursorColor: noteEditorInk,
                  dragHandleColor: noteEditorInk,
                  selectionColor: noteEditorInk.withValues(alpha: 0.15),
                  textStyleConfiguration: TextStyleConfiguration(
                    text: const TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 17,
                      height: 1.26,
                      color: noteEditorInk,
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
                    code: const TextStyle(
                      color: noteEditorInk,
                      backgroundColor: noteEditorChip,
                      fontFamily: 'JetBrains Mono',
                      fontSize: 14,
                    ),
                    lineHeight: 1.26,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        NoteFormattingToolbar(
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

class NoteFormattingToolbar extends StatelessWidget {
  const NoteFormattingToolbar({
    super.key,
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
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
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
            _ToolIcon(icon: Icons.horizontal_rule_rounded, onTap: onDivider),
            _ToolIcon(icon: Icons.image_outlined, onTap: onImage),
            _ToolIcon(icon: Icons.attach_file_rounded, onTap: onFile),
          ],
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
        color: noteEditorChip,
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
                  color: noteEditorInk,
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
        color: noteEditorChip,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            height: 38,
            width: 42,
            child: Icon(icon, size: 20, color: noteEditorInk),
          ),
        ),
      ),
    );
  }
}

const noteEditorPaper = Color(0xFFFBFAF6);
const noteEditorInk = Color(0xFF211E19);
const noteEditorMuted = Color(0xFF928A80);
const noteEditorChip = Color(0xFFF1EEE8);

final Map<String, BlockComponentBuilder> noteEditorBlockComponentBuilders = {
  ...standardBlockComponentBuilderMap,
  ParagraphBlockKeys.type: ParagraphBlockComponentBuilder(
    configuration: _noteCompactBlockConfiguration(
      placeholderText: (_) => ' ',
      padding: (_) => const EdgeInsets.symmetric(vertical: 1),
    ),
  ),
  TodoListBlockKeys.type: TodoListBlockComponentBuilder(
    configuration: _noteCompactBlockConfiguration(
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
    configuration: _noteCompactBlockConfiguration(
      placeholderText: (_) => AppFlowyEditorL10n.current.listItemPlaceholder,
      padding: (_) => const EdgeInsets.symmetric(vertical: 1),
    ),
  ),
  NumberedListBlockKeys.type: NumberedListBlockComponentBuilder(
    configuration: _noteCompactBlockConfiguration(
      placeholderText: (_) => AppFlowyEditorL10n.current.listItemPlaceholder,
      padding: (_) => const EdgeInsets.symmetric(vertical: 1),
    ),
  ),
  QuoteBlockKeys.type: QuoteBlockComponentBuilder(
    configuration: _noteCompactBlockConfiguration(
      placeholderText: (_) => AppFlowyEditorL10n.current.quote,
      padding: (_) => const EdgeInsets.symmetric(vertical: 2),
    ),
  ),
  HeadingBlockKeys.type: HeadingBlockComponentBuilder(
    configuration: _noteCompactBlockConfiguration(
      placeholderText: (node) =>
          'Heading ${node.attributes[HeadingBlockKeys.level]}',
      padding: (_) => const EdgeInsets.only(top: 8, bottom: 2),
    ),
  ),
  DividerBlockKeys.type: DividerBlockComponentBuilder(
    configuration: _noteCompactBlockConfiguration(
      padding: (_) => const EdgeInsets.symmetric(vertical: 6),
    ),
    lineColor: const Color(0xFFE4DED5),
    height: 8,
  ),
};

BlockComponentConfiguration _noteCompactBlockConfiguration({
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
