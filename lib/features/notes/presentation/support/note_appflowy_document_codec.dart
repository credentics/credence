import 'dart:convert';

import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:pass_doc_manager/domain/notes/entities/secure_note_block_entity.dart';
import 'package:pass_doc_manager/domain/notes/entities/secure_note_entity.dart';

class NoteAppFlowyDocumentCodec {
  const NoteAppFlowyDocumentCodec._();

  static const blockIdKey = 'vaultic_block_id';
  static const blockAttachmentPathKey = 'vaultic_attachment_path';

  static Document documentFromDetail(SecureNoteDetailEntity? detail) {
    if (detail == null || detail.blocks.isEmpty) {
      return Document.blank(withInitialText: true);
    }
    final children = <Node>[];
    final blocks = detail.blocks.toList(growable: false)
      ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
    for (final block in blocks) {
      final node = nodeFromBlock(block);
      if (node != null) {
        children.add(node);
      }
    }
    if (children.isEmpty) {
      children.add(paragraphNode());
    }
    return Document(
      root: Node(type: 'page', children: children),
    );
  }

  static Node? nodeFromBlock(SecureNoteBlockEntity block) {
    try {
      final map = Map<String, Object>.from(
        jsonDecode(block.contentJson) as Map,
      );
      final data = Map<String, Object>.from(map['data'] as Map? ?? {});
      data[blockIdKey] = block.id;
      map['data'] = data;
      return Node.fromJson(map);
    } catch (_) {
      return paragraphNode(text: block.plainText);
    }
  }

  static List<SecureNoteBlockEntity> blocksFromDocument({
    required String noteId,
    required Document document,
    required DateTime now,
    required Map<String, SecureNoteBlockEntity> previousBlocks,
  }) {
    final blocks = <SecureNoteBlockEntity>[];
    final children = document.root.children;
    for (var i = 0; i < children.length; i++) {
      final node = children[i];
      final serialized = _serializeNode(node, fallbackId: node.id);
      final blockId = serialized.blockId;
      final previous = previousBlocks[blockId];
      final contentHash = _contentHash(serialized.contentJson);
      blocks.add(
        SecureNoteBlockEntity(
          id: blockId,
          noteId: noteId,
          type: _semanticType(node),
          contentJson: serialized.contentJson,
          plainText: plainTextFromNode(node).trim(),
          orderIndex: i,
          createdAt: previous?.createdAt ?? now,
          updatedAt:
              previous?.contentHash == contentHash &&
                  previous?.orderIndex == i &&
                  previous?.type == _semanticType(node)
              ? previous!.updatedAt
              : now,
          contentHash: contentHash,
        ),
      );
    }
    return blocks;
  }

  static _SerializedNode _serializeNode(
    Node node, {
    required String fallbackId,
  }) {
    final json = Map<String, Object>.from(node.toJson());
    final data = Map<String, Object>.from(json['data'] as Map? ?? {});
    final existingId = '${data[blockIdKey] ?? ''}'.trim();
    final blockId = existingId.isEmpty ? fallbackId : existingId;
    data[blockIdKey] = blockId;
    json['data'] = data;
    return _SerializedNode(
      blockId: blockId,
      contentJson: const JsonEncoder().convert(json),
    );
  }

  static String plainTextFromDocument(Document document) {
    return document.root.children
        .map(plainTextFromNode)
        .where((line) => line.trim().isNotEmpty)
        .join('\n')
        .trim();
  }

  static String plainTextFromNode(Node node) {
    final buffer = StringBuffer();
    final deltaText = node.delta?.toPlainText();
    if (deltaText != null && deltaText.isNotEmpty) {
      buffer.write(deltaText);
    }
    for (final child in node.children) {
      final childText = plainTextFromNode(child);
      if (childText.trim().isEmpty) continue;
      if (buffer.isNotEmpty) buffer.write('\n');
      buffer.write(childText);
    }
    return buffer.toString();
  }

  static String previewFromDocument(Document document) {
    final plain = plainTextFromDocument(
      document,
    ).replaceAll(RegExp(r'\s+'), ' ');
    if (plain.length <= 180) return plain;
    return '${plain.substring(0, 180).trimRight()}...';
  }

  static String titleFromDocument(Document document) {
    final firstText = document.root.children
        .map(plainTextFromNode)
        .map((line) => line.trim())
        .firstWhere((line) => line.isNotEmpty, orElse: () => '');
    if (firstText.length <= 80) return firstText;
    return firstText.substring(0, 80).trimRight();
  }

  static String _semanticType(Node node) {
    switch (node.type) {
      case HeadingBlockKeys.type:
        return 'heading';
      case TodoListBlockKeys.type:
        return 'checklist';
      case BulletedListBlockKeys.type:
        return 'bullet_list';
      case NumberedListBlockKeys.type:
        return 'numbered_list';
      case QuoteBlockKeys.type:
        return 'quote';
      case DividerBlockKeys.type:
        return 'divider';
      case ImageBlockKeys.type:
        return 'image';
      default:
        return node.type;
    }
  }

  static String _contentHash(String content) {
    var hash = 0xcbf29ce484222325;
    for (final unit in utf8.encode(content)) {
      hash ^= unit;
      hash = (hash * 0x100000001b3) & 0x7fffffffffffffff;
    }
    return hash.toRadixString(16);
  }
}

class _SerializedNode {
  const _SerializedNode({required this.blockId, required this.contentJson});

  final String blockId;
  final String contentJson;
}
