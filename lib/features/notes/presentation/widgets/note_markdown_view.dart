import 'package:flutter/material.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:pass_doc_manager/app/theme/app_palette.dart';
import 'package:pass_doc_manager/features/notes/presentation/support/note_markdown_support.dart';

enum NoteMarkdownViewStyle { standard, reference }

class NoteMarkdownView extends StatelessWidget {
  const NoteMarkdownView({
    required this.markdown,
    super.key,
    this.emptyLabel = 'Nothing to preview yet.',
    this.style = NoteMarkdownViewStyle.standard,
  });

  final String markdown;
  final String emptyLabel;
  final NoteMarkdownViewStyle style;

  @override
  Widget build(BuildContext context) {
    final trimmed = markdown.trim();
    if (trimmed.isEmpty) {
      return Text(
        emptyLabel,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: context.appPalette.textMuted,
        ),
      );
    }

    final nodes = NoteMarkdownSupport.parseMarkdown(trimmed);
    final builder = _MarkdownWidgetBuilder(context, style);
    final widgets = nodes
        .map(builder.buildBlock)
        .whereType<Widget>()
        .toList(growable: false);

    return SelectableRegion(
      focusNode: FocusNode(skipTraversal: true),
      selectionControls: materialTextSelectionControls,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: widgets,
      ),
    );
  }
}

class _MarkdownWidgetBuilder {
  _MarkdownWidgetBuilder(this.context, this.style)
    : palette = context.appPalette;

  final BuildContext context;
  final AppPalette palette;
  final NoteMarkdownViewStyle style;

  bool get _isReference => style == NoteMarkdownViewStyle.reference;

  Widget? buildBlock(md.Node node, {int listDepth = 0}) {
    if (node is md.Text) {
      final text = node.text.trim();
      if (text.isEmpty) {
        return null;
      }
      return _paragraph([node]);
    }
    if (node is! md.Element) {
      return null;
    }

    switch (node.tag) {
      case 'p':
        return _paragraph(node.children ?? const <md.Node>[]);
      case 'h1':
        return _heading(
          node.textContent,
          _isReference ? 22 : 30,
          _isReference ? FontWeight.w700 : FontWeight.w800,
        );
      case 'h2':
        return _heading(
          node.textContent,
          _isReference ? 16 : 26,
          _isReference ? FontWeight.w700 : FontWeight.w800,
        );
      case 'h3':
        return _heading(
          node.textContent,
          _isReference ? 15.5 : 22,
          _isReference ? FontWeight.w700 : FontWeight.w800,
        );
      case 'h4':
        return _heading(node.textContent, 19, FontWeight.w700);
      case 'h5':
        return _heading(node.textContent, 17, FontWeight.w700);
      case 'h6':
        return _heading(node.textContent, 15, FontWeight.w700);
      case 'blockquote':
        return _blockquote(node.children ?? const <md.Node>[]);
      case 'pre':
        return _codeBlock(node.textContent);
      case 'hr':
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 18),
          child: Divider(height: 1, color: palette.stroke),
        );
      case 'ul':
        return _list(node, ordered: false, listDepth: listDepth);
      case 'ol':
        return _list(node, ordered: true, listDepth: listDepth);
      case 'table':
        return _table(node);
      default:
        if (node.children == null || node.children!.isEmpty) {
          return null;
        }
        final children = node.children!
            .map((child) => buildBlock(child, listDepth: listDepth))
            .whereType<Widget>()
            .toList(growable: false);
        if (children.isEmpty) {
          return null;
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: children,
        );
    }
  }

  Widget _heading(String value, double size, FontWeight weight) {
    return Padding(
      padding: _isReference
          ? EdgeInsets.only(
              top: size >= 20 ? 0 : 18,
              bottom: size >= 20 ? 8 : 6,
            )
          : EdgeInsets.only(
              top: size >= 26 ? 10 : 8,
              bottom: size >= 22 ? 12 : 10,
            ),
      child: Text(
        value.trim(),
        style: TextStyle(
          fontFamily: 'Manrope',
          fontSize: size,
          fontWeight: weight,
          height: _isReference ? 1.2 : 1.18,
          color: palette.textPrimary,
          letterSpacing: _isReference ? -0.2 : (size >= 26 ? -0.8 : -0.3),
        ),
      ),
    );
  }

  Widget _paragraph(List<md.Node> nodes) {
    final baseStyle = TextStyle(
      fontFamily: 'Manrope',
      fontSize: _isReference ? 14.5 : 15.5,
      fontWeight: FontWeight.w500,
      height: _isReference ? 1.55 : 1.6,
      color: palette.textPrimary,
    );
    return Padding(
      padding: EdgeInsets.only(bottom: _isReference ? 12 : 14),
      child: RichText(
        text: TextSpan(
          style: baseStyle,
          children: _inlineSpans(nodes, baseStyle: baseStyle),
        ),
      ),
    );
  }

  Widget _blockquote(List<md.Node> nodes) {
    final blocks = nodes
        .map((child) => buildBlock(child))
        .whereType<Widget>()
        .toList(growable: false);
    return Padding(
      padding: EdgeInsets.only(bottom: _isReference ? 12 : 16),
      child: Container(
        width: double.infinity,
        padding: _isReference
            ? const EdgeInsets.fromLTRB(12, 4, 0, 0)
            : const EdgeInsets.fromLTRB(16, 14, 16, 4),
        decoration: BoxDecoration(
          color: _isReference ? Colors.transparent : palette.surfaceSoft,
          borderRadius: BorderRadius.circular(_isReference ? 0 : 16),
          border: Border(
            left: BorderSide(
              color: _isReference ? palette.textPrimary : palette.primary,
              width: _isReference ? 2 : 4,
            ),
          ),
        ),
        child: DefaultTextStyle(
          style: TextStyle(
            fontFamily: 'Manrope',
            fontSize: _isReference ? 14.5 : 15,
            fontWeight: FontWeight.w500,
            fontStyle: _isReference ? FontStyle.italic : FontStyle.normal,
            height: _isReference ? 1.55 : 1.6,
            color: palette.textSecondary,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: blocks,
          ),
        ),
      ),
    );
  }

  Widget _codeBlock(String value) {
    final code = value.trimRight();
    return Padding(
      padding: EdgeInsets.only(bottom: _isReference ? 12 : 16),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(_isReference ? 12 : 16),
        decoration: BoxDecoration(
          color: palette.surfaceSoft,
          borderRadius: BorderRadius.circular(_isReference ? 12 : 18),
          border: _isReference ? null : Border.all(color: palette.stroke),
        ),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Text(
            code,
            style: TextStyle(
              fontSize: _isReference ? 12 : 13.5,
              fontWeight: FontWeight.w500,
              height: _isReference ? 1.5 : 1.55,
              color: palette.textPrimary,
              fontFamily: 'JetBrains Mono',
            ),
          ),
        ),
      ),
    );
  }

  Widget _list(md.Element element, {required bool ordered, int listDepth = 0}) {
    final items =
        element.children
            ?.whereType<md.Element>()
            .where((child) => child.tag == 'li')
            .toList(growable: false) ??
        const <md.Element>[];
    return Padding(
      padding: EdgeInsets.only(bottom: _isReference ? 12 : 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < items.length; i++)
            _listItem(
              items[i],
              ordered: ordered,
              index: i + 1,
              listDepth: listDepth,
            ),
        ],
      ),
    );
  }

  Widget _listItem(
    md.Element element, {
    required bool ordered,
    required int index,
    required int listDepth,
  }) {
    final nestedLists = <Widget>[];
    final paragraphNodes = <md.Node>[];

    for (final child in element.children ?? const <md.Node>[]) {
      if (child is md.Element && (child.tag == 'ul' || child.tag == 'ol')) {
        nestedLists.add(
          buildBlock(child, listDepth: listDepth + 1) ??
              const SizedBox.shrink(),
        );
      } else if (child is md.Element && child.tag == 'p') {
        paragraphNodes.addAll(child.children ?? const <md.Node>[]);
      } else {
        paragraphNodes.add(child);
      }
    }

    final marker = ordered ? '$index.' : '•';
    final baseStyle = TextStyle(
      fontFamily: 'Manrope',
      fontSize: _isReference ? 14.5 : 15.5,
      fontWeight: FontWeight.w500,
      height: _isReference ? 1.55 : 1.6,
      color: palette.textPrimary,
    );
    return Padding(
      padding: EdgeInsets.only(
        left: listDepth * 18.0,
        bottom: _isReference ? 4 : (nestedLists.isEmpty ? 8 : 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: _isReference ? 18 : 24,
                child: Text(
                  marker,
                  style: TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: _isReference ? 14.5 : 15,
                    fontWeight: FontWeight.w700,
                    height: _isReference ? 1.55 : 1.6,
                    color: palette.textPrimary,
                  ),
                ),
              ),
              Expanded(
                child: paragraphNodes.isEmpty
                    ? const SizedBox.shrink()
                    : RichText(
                        text: TextSpan(
                          style: baseStyle,
                          children: _inlineSpans(
                            paragraphNodes,
                            baseStyle: baseStyle,
                          ),
                        ),
                      ),
              ),
            ],
          ),
          if (nestedLists.isNotEmpty) ...nestedLists,
        ],
      ),
    );
  }

  Widget _table(md.Element element) {
    final rows = <TableRow>[];
    var headerRow = true;
    for (final section in element.children ?? const <md.Node>[]) {
      if (section is! md.Element) {
        continue;
      }
      for (final row in section.children ?? const <md.Node>[]) {
        if (row is! md.Element || row.tag != 'tr') {
          continue;
        }
        final cells =
            row.children
                ?.whereType<md.Element>()
                .where((cell) => cell.tag == 'th' || cell.tag == 'td')
                .toList(growable: false) ??
            const <md.Element>[];
        if (cells.isEmpty) {
          continue;
        }
        rows.add(
          TableRow(
            decoration: BoxDecoration(
              color: _isReference
                  ? Colors.transparent
                  : (headerRow ? palette.surfaceSoft : palette.surface),
            ),
            children: [
              for (final cell in cells)
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: _isReference ? 0 : 12,
                    vertical: _isReference ? 6 : 10,
                  ),
                  child: RichText(
                    text: TextSpan(
                      style: TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: _isReference ? 13 : 14,
                        fontWeight: cell.tag == 'th'
                            ? FontWeight.w700
                            : FontWeight.w500,
                        height: _isReference ? 1.35 : 1.45,
                        color: palette.textPrimary,
                      ),
                      children: _inlineSpans(
                        cell.children ?? const <md.Node>[],
                        baseStyle: TextStyle(
                          fontFamily: 'Manrope',
                          fontSize: _isReference ? 13 : 14,
                          fontWeight: cell.tag == 'th'
                              ? FontWeight.w700
                              : FontWeight.w500,
                          height: _isReference ? 1.35 : 1.45,
                          color: palette.textPrimary,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
        headerRow = false;
      }
    }

    if (rows.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: EdgeInsets.only(bottom: _isReference ? 12 : 18),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(_isReference ? 0 : 18),
          child: Container(
            decoration: BoxDecoration(
              border: _isReference ? null : Border.all(color: palette.stroke),
              borderRadius: BorderRadius.circular(_isReference ? 0 : 18),
            ),
            child: Table(
              defaultVerticalAlignment: TableCellVerticalAlignment.middle,
              border: _isReference
                  ? TableBorder(
                      horizontalInside: BorderSide(color: palette.stroke),
                    )
                  : TableBorder.symmetric(
                      inside: BorderSide(color: palette.stroke),
                    ),
              children: rows,
            ),
          ),
        ),
      ),
    );
  }

  List<InlineSpan> _inlineSpans(
    List<md.Node> nodes, {
    required TextStyle baseStyle,
  }) {
    final spans = <InlineSpan>[];
    for (final node in nodes) {
      if (node is md.Text) {
        spans.add(TextSpan(text: node.text, style: baseStyle));
        continue;
      }
      if (node is! md.Element) {
        continue;
      }

      switch (node.tag) {
        case 'strong':
          spans.add(
            TextSpan(
              style: baseStyle.copyWith(
                fontWeight: _isReference ? FontWeight.w700 : FontWeight.w800,
              ),
              children: _inlineSpans(
                node.children ?? const <md.Node>[],
                baseStyle: baseStyle.copyWith(
                  fontWeight: _isReference ? FontWeight.w700 : FontWeight.w800,
                ),
              ),
            ),
          );
          break;
        case 'em':
          spans.add(
            TextSpan(
              style: baseStyle.copyWith(fontStyle: FontStyle.italic),
              children: _inlineSpans(
                node.children ?? const <md.Node>[],
                baseStyle: baseStyle.copyWith(fontStyle: FontStyle.italic),
              ),
            ),
          );
          break;
        case 'del':
          spans.add(
            TextSpan(
              style: baseStyle.copyWith(decoration: TextDecoration.lineThrough),
              children: _inlineSpans(
                node.children ?? const <md.Node>[],
                baseStyle: baseStyle.copyWith(
                  decoration: TextDecoration.lineThrough,
                ),
              ),
            ),
          );
          break;
        case 'code':
          spans.add(
            WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 1),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: palette.surfaceSoft,
                  borderRadius: BorderRadius.circular(_isReference ? 4 : 8),
                ),
                child: Text(
                  node.textContent,
                  style: TextStyle(
                    fontSize: baseStyle.fontSize == null
                        ? 13.5
                        : baseStyle.fontSize! - 1,
                    fontWeight: FontWeight.w600,
                    color: palette.textPrimary,
                    fontFamily: 'JetBrains Mono',
                  ),
                ),
              ),
            ),
          );
          break;
        case 'a':
          spans.add(
            TextSpan(
              style: baseStyle.copyWith(
                color: _isReference ? palette.textPrimary : palette.primary,
                decoration: TextDecoration.underline,
                decorationThickness: _isReference ? 1 : null,
                fontWeight: FontWeight.w700,
              ),
              children: _inlineSpans(
                node.children ?? const <md.Node>[],
                baseStyle: baseStyle.copyWith(
                  color: _isReference ? palette.textPrimary : palette.primary,
                  decoration: TextDecoration.underline,
                  decorationThickness: _isReference ? 1 : null,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          );
          break;
        case 'br':
          spans.add(const TextSpan(text: '\n'));
          break;
        default:
          spans.addAll(
            _inlineSpans(
              node.children ?? const <md.Node>[],
              baseStyle: baseStyle,
            ),
          );
      }
    }
    return spans;
  }
}
