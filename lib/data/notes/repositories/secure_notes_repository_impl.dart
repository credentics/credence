import 'dart:convert';

import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:pass_doc_manager/core/constants/internal_collection_ids.dart';
import 'package:pass_doc_manager/data/collections/datasources/local/collections_local_data_source.dart';
import 'package:pass_doc_manager/data/collections/dtos/collection_record_dto.dart';
import 'package:pass_doc_manager/data/notes/datasources/local/secure_notes_local_data_source.dart';
import 'package:pass_doc_manager/domain/notes/entities/secure_note_block_entity.dart';
import 'package:pass_doc_manager/domain/notes/entities/secure_note_entity.dart';
import 'package:pass_doc_manager/domain/notes/repositories/secure_notes_repository.dart';

const _legacyMigrationMetaKey = 'legacy_secure_notes_migrated_v1';
const _blockIdKey = 'vaultic_block_id';
const _legacyMarkdownContentKey = 'markdownContent';
const _legacyRichContentKey = 'richContent';

class SecureNotesRepositoryImpl implements SecureNotesRepository {
  const SecureNotesRepositoryImpl({
    required this.local,
    required this.legacyCollectionsLocal,
  });

  SecureNotesLocalDataSource get _local => local;

  final SecureNotesLocalDataSource local;
  final CollectionsLocalDataSource legacyCollectionsLocal;

  @override
  Future<void> migrateLegacyNotesIfNeeded() async {
    final migrated = await _local.readMeta(_legacyMigrationMetaKey);
    if (migrated == 'true') return;

    final existingIds = (await _local.getNotes())
        .map((note) => note.id)
        .toSet();

    final collections = await legacyCollectionsLocal.getCollections();
    CollectionRecordDto? legacyCollection;
    for (final collection in collections) {
      if (collection.id == internalSecureNotesCollectionId) {
        legacyCollection = collection;
        break;
      }
    }
    if (legacyCollection == null || legacyCollection.blocks.isEmpty) {
      await _local.writeMeta(_legacyMigrationMetaKey, 'true');
      return;
    }

    final notes = legacyCollection.blocks.toList(growable: false)
      ..sort((a, b) => a.position.compareTo(b.position));
    for (final legacyNote in notes) {
      final noteId = 'legacy_${legacyNote.id}';
      if (existingIds.contains(noteId)) {
        continue;
      }
      await _migrateLegacyNote(legacyNote, noteId: noteId);
    }
    await _local.writeMeta(_legacyMigrationMetaKey, 'true');
  }

  Future<void> _migrateLegacyNote(
    CollectionBlockRecordDto legacyNote, {
    required String noteId,
  }) async {
    final createdAt =
        DateTime.tryParse(legacyNote.createdAtIso) ??
        DateTime.fromMillisecondsSinceEpoch(0);
    final updatedAt = DateTime.tryParse(legacyNote.updatedAtIso) ?? createdAt;
    final markdown = _legacyMarkdownFromBlock(legacyNote);
    final document = markdown.trim().isEmpty
        ? Document.blank(withInitialText: true)
        : markdownToDocument(markdown);
    await _local.createNote(id: noteId, title: '', preview: '', now: createdAt);
    final blocks = <SecureNoteBlockEntity>[];
    final children = document.root.children.isEmpty
        ? [paragraphNode()]
        : document.root.children;
    for (var i = 0; i < children.length; i++) {
      final node = children[i];
      final blockId = '${noteId}_block_$i';
      final contentJson = _serializeLegacyNode(node, blockId);
      blocks.add(
        SecureNoteBlockEntity(
          id: blockId,
          noteId: noteId,
          type: node.type,
          contentJson: contentJson,
          plainText: _plainTextFromNode(node).trim(),
          orderIndex: i,
          createdAt: createdAt,
          updatedAt: updatedAt,
          contentHash: _contentHash(contentJson),
        ),
      );
    }
    final title = legacyNote.title.trim().isNotEmpty
        ? legacyNote.title.trim()
        : _fallbackTitle(markdown);
    final preview = _preview(markdown);
    await _local.saveNoteSnapshot(
      SecureNoteSnapshotEntity(
        id: noteId,
        title: title.isEmpty ? 'Untitled' : title,
        preview: preview,
        updatedAt: updatedAt,
        blocks: blocks,
      ),
    );
  }

  @override
  Future<SecureNoteDetailEntity> createNote({
    String title = '',
    String preview = '',
  }) async {
    final now = DateTime.now();
    final id = 'note_${now.microsecondsSinceEpoch}';
    final detail = await _local.createNote(
      id: id,
      title: title,
      preview: preview,
      now: now,
    );
    return detail.toEntity();
  }

  @override
  Future<void> deleteNote(String id) {
    return _local.deleteNote(id);
  }

  @override
  Future<SecureNoteDetailEntity> getNoteById(String id) async {
    return (await _local.getNoteById(id)).toEntity();
  }

  @override
  Future<List<SecureNoteSummaryEntity>> getNotes() async {
    final records = await _local.getNotes();
    return records
        .map((item) => item.toSummaryEntity())
        .toList(growable: false);
  }

  @override
  Future<void> saveNoteSnapshot(SecureNoteSnapshotEntity snapshot) {
    return _local.saveNoteSnapshot(snapshot);
  }

  String _legacyMarkdownFromBlock(CollectionBlockRecordDto note) {
    final markdown = (note.metadata[_legacyMarkdownContentKey] ?? '').trim();
    if (markdown.isNotEmpty) return markdown;
    final richContent = (note.metadata[_legacyRichContentKey] ?? '').trim();
    if (richContent.isNotEmpty) return richContent;
    return note.description.trim();
  }

  String _serializeLegacyNode(Node node, String blockId) {
    final json = Map<String, Object>.from(node.toJson());
    final data = Map<String, Object>.from(json['data'] as Map? ?? {});
    data[_blockIdKey] = blockId;
    json['data'] = data;
    return const JsonEncoder().convert(json);
  }

  String _plainTextFromNode(Node node) {
    final buffer = StringBuffer();
    final deltaText = node.delta?.toPlainText();
    if (deltaText != null && deltaText.isNotEmpty) {
      buffer.write(deltaText);
    }
    for (final child in node.children) {
      final childText = _plainTextFromNode(child);
      if (childText.trim().isEmpty) continue;
      if (buffer.isNotEmpty) buffer.write('\n');
      buffer.write(childText);
    }
    return buffer.toString();
  }

  String _fallbackTitle(String markdown) {
    return markdown
        .split('\n')
        .map((line) => line.trim().replaceFirst(RegExp(r'^#+\s*'), ''))
        .firstWhere((line) => line.isNotEmpty, orElse: () => '');
  }

  String _preview(String markdown) {
    final text = markdown.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (text.length <= 180) return text;
    return '${text.substring(0, 180).trimRight()}...';
  }

  String _contentHash(String content) {
    var hash = 0xcbf29ce484222325;
    for (final unit in utf8.encode(content)) {
      hash ^= unit;
      hash = (hash * 0x100000001b3) & 0x7fffffffffffffff;
    }
    return hash.toRadixString(16);
  }
}
