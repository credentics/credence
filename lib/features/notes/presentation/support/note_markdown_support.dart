import 'dart:convert';

import 'package:markdown/markdown.dart' as md;
import 'package:pass_doc_manager/data/collections/dtos/collection_record_dto.dart';

class NoteMarkdownSupport {
  const NoteMarkdownSupport._();

  static const markdownContentKey = 'markdownContent';
  static const richContentKey = 'richContent';
  static const contentFormatKey = 'contentFormat';
  static const markdownContentFormat = 'markdown';

  static String markdownFromBlock(CollectionBlockRecordDto note) {
    final markdown = (note.metadata[markdownContentKey] ?? '').trim();
    if (markdown.isNotEmpty) {
      return markdown;
    }

    final richContent = (note.metadata[richContentKey] ?? '').trim();
    if (richContent.isNotEmpty) {
      final converted = _markdownFromRichDeltaJson(richContent).trim();
      if (converted.isNotEmpty) {
        return converted;
      }
    }

    return note.description.trim();
  }

  static String plainTextFromMarkdown(String markdown) {
    final nodes = _parseMarkdown(markdown);
    final buffer = StringBuffer();
    for (final node in nodes) {
      _appendPlainText(buffer, node, isRoot: true);
    }
    final normalized = buffer
        .toString()
        .replaceAll(RegExp(r'\n{3,}'), '\n\n')
        .replaceAll(RegExp(r'[ \t]+\n'), '\n')
        .trim();
    return normalized;
  }

  static String previewFromMarkdown(String markdown, {int maxLength = 180}) {
    final text = plainTextFromMarkdown(markdown);
    if (text.length <= maxLength) {
      return text;
    }
    return '${text.substring(0, maxLength).trimRight()}...';
  }

  static List<md.Node> parseMarkdown(String markdown) {
    return _parseMarkdown(markdown);
  }

  static List<md.Node> _parseMarkdown(String markdown) {
    final normalized = markdown.replaceAll('\r\n', '\n');
    final document = md.Document(
      extensionSet: md.ExtensionSet.gitHubWeb,
      encodeHtml: false,
    );
    return document.parseLines(const LineSplitter().convert(normalized));
  }

  static void _appendPlainText(
    StringBuffer buffer,
    md.Node node, {
    bool isRoot = false,
  }) {
    if (node is md.Text) {
      buffer.write(node.text);
      return;
    }
    if (node is! md.Element) {
      return;
    }

    switch (node.tag) {
      case 'br':
        buffer.writeln();
        return;
      case 'hr':
        buffer.writeln();
        return;
      case 'code':
      case 'pre':
        buffer.write(node.textContent);
        if (isRoot) {
          buffer.writeln();
          buffer.writeln();
        }
        return;
      case 'li':
        buffer.write(node.textContent);
        buffer.writeln();
        return;
      case 'p':
      case 'h1':
      case 'h2':
      case 'h3':
      case 'h4':
      case 'h5':
      case 'h6':
      case 'blockquote':
      case 'table':
      case 'ul':
      case 'ol':
        for (final child in node.children ?? const <md.Node>[]) {
          _appendPlainText(buffer, child);
        }
        if (isRoot) {
          buffer.writeln();
          buffer.writeln();
        }
        return;
      default:
        for (final child in node.children ?? const <md.Node>[]) {
          _appendPlainText(buffer, child);
        }
        if (isRoot) {
          buffer.writeln();
        }
    }
  }

  static String _markdownFromRichDeltaJson(String richJson) {
    try {
      final decoded = jsonDecode(richJson);
      if (decoded is! List) {
        return '';
      }
      final writer = _DeltaMarkdownWriter();
      for (final rawOperation in decoded) {
        if (rawOperation is! Map) {
          continue;
        }
        writer.addOperation(Map<String, dynamic>.from(rawOperation));
      }
      return writer.finish();
    } catch (_) {
      return '';
    }
  }
}

class _DeltaMarkdownWriter {
  final StringBuffer _buffer = StringBuffer();
  final StringBuffer _lineBuffer = StringBuffer();
  final Map<int, int> _orderedListCounts = <int, int>{};
  bool _insideCodeBlock = false;

  void addOperation(Map<String, dynamic> operation) {
    final insert = operation['insert'];
    final attributes = operation['attributes'] is Map
        ? Map<String, dynamic>.from(operation['attributes'] as Map)
        : const <String, dynamic>{};

    if (insert is String) {
      _addTextInsert(insert, attributes);
      return;
    }

    if (insert is Map && insert.containsKey('hr')) {
      _finalizePendingLine();
      _closeCodeBlockIfNeeded();
      _buffer.writeln('---');
      _buffer.writeln();
    }
  }

  String finish() {
    _finalizePendingLine();
    _closeCodeBlockIfNeeded();
    return _buffer.toString().replaceAll(RegExp(r'\n{3,}'), '\n\n').trim();
  }

  void _addTextInsert(String text, Map<String, dynamic> attributes) {
    final pieces = text.split('\n');
    for (var i = 0; i < pieces.length; i++) {
      final piece = pieces[i];
      if (piece.isNotEmpty) {
        _lineBuffer.write(_applyInlineMarkdown(piece, attributes));
      }

      if (i < pieces.length - 1) {
        _finalizeLine(attributes);
      }
    }
  }

  void _finalizePendingLine() {
    if (_lineBuffer.isEmpty) {
      return;
    }
    _finalizeLine(const <String, dynamic>{});
  }

  void _finalizeLine(Map<String, dynamic> attributes) {
    final rawLine = _lineBuffer.toString();
    _lineBuffer.clear();

    final block = '${attributes['block'] ?? ''}'.trim();
    final headingLevel = attributes['heading'] is int
        ? attributes['heading'] as int
        : int.tryParse('${attributes['heading'] ?? ''}');
    final indent = attributes['indent'] is int
        ? attributes['indent'] as int
        : int.tryParse('${attributes['indent'] ?? ''}') ?? 0;
    final checked = attributes['checked'] == true;

    if (block == 'code') {
      if (!_insideCodeBlock) {
        _closeOpenParagraphSpacing();
        _buffer.writeln('```');
        _insideCodeBlock = true;
      }
      _buffer.writeln(_stripInlineMarkdown(rawLine));
      _orderedListCounts.clear();
      return;
    }

    _closeCodeBlockIfNeeded();

    if (headingLevel != null && headingLevel > 0) {
      _buffer.writeln('${'#' * headingLevel} ${rawLine.trim()}');
      _buffer.writeln();
      _orderedListCounts.clear();
      return;
    }

    if (block == 'ul' || block == 'cl') {
      _resetOrderedCountsFromDepth(indent);
      final prefix = block == 'cl'
          ? '${'  ' * indent}- [${checked ? 'x' : ' '}] '
          : '${'  ' * indent}- ';
      _buffer.writeln('$prefix${rawLine.trim()}');
      return;
    }

    if (block == 'ol') {
      final nextIndex = (_orderedListCounts[indent] ?? 0) + 1;
      _orderedListCounts[indent] = nextIndex;
      _orderedListCounts.removeWhere((key, _) => key > indent);
      final prefix = '${'  ' * indent}$nextIndex. ';
      _buffer.writeln('$prefix${rawLine.trim()}');
      return;
    }

    _orderedListCounts.clear();

    if (block == 'quote') {
      _buffer.writeln('> ${rawLine.trim()}');
      return;
    }

    final trimmed = rawLine.trimRight();
    if (trimmed.isEmpty) {
      _buffer.writeln();
      return;
    }

    _buffer.writeln(trimmed);
    _buffer.writeln();
  }

  void _closeCodeBlockIfNeeded() {
    if (!_insideCodeBlock) {
      return;
    }
    _buffer.writeln('```');
    _buffer.writeln();
    _insideCodeBlock = false;
  }

  void _closeOpenParagraphSpacing() {
    final current = _buffer.toString();
    if (current.isEmpty || current.endsWith('\n\n')) {
      return;
    }
    _buffer.writeln();
  }

  void _resetOrderedCountsFromDepth(int depth) {
    _orderedListCounts.removeWhere((key, _) => key >= depth);
  }

  String _applyInlineMarkdown(String text, Map<String, dynamic> attributes) {
    var value = text;
    final isInlineCode = attributes['code'] == true;
    if (isInlineCode) {
      value = '`$value`';
    }
    if (attributes['link'] != null) {
      value = '[${_stripInlineMarkdown(value)}](${attributes['link']})';
    }
    if (attributes['bold'] == true) {
      value = '**$value**';
    }
    if (attributes['italic'] == true) {
      value = '*$value*';
    }
    if (attributes['strikethrough'] == true) {
      value = '~~$value~~';
    }
    if (attributes['underline'] == true) {
      value = '<u>$value</u>';
    }
    return value;
  }

  String _stripInlineMarkdown(String text) {
    return text
        .replaceAll(RegExp(r'[`*_~]'), '')
        .replaceAll(RegExp(r'</?u>'), '');
  }
}
