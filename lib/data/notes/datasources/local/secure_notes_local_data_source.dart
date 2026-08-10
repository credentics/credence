import 'dart:async';
import 'dart:convert';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pass_doc_manager/data/notes/dtos/secure_note_dto.dart';
import 'package:pass_doc_manager/domain/notes/entities/secure_note_entity.dart';
import 'package:sqflite/sqflite.dart';

class SecureNotesLocalDataSource {
  SecureNotesLocalDataSource();

  static const _dbName = 'vault_secure_notes.sqlite';
  static const _schemaVersion = 1;

  Future<Database>? _dbFuture;

  Future<Database> get _database {
    final existing = _dbFuture;
    if (existing != null) return existing;
    _dbFuture = _openDatabase().catchError((Object error) {
      // Allow retry after a transient SQLite open failure instead of caching
      // a failed Future for the rest of the app session.
      _dbFuture = null;
      throw error;
    });
    return _dbFuture!;
  }

  static Future<SecureNotesLocalDataSource> create() async {
    return SecureNotesLocalDataSource();
  }

  static Future<Database> _openDatabase() async {
    final supportDir = await getApplicationSupportDirectory();
    if (!await supportDir.exists()) {
      await supportDir.create(recursive: true);
    }
    final dbPath = p.join(supportDir.path, _dbName);
    return openDatabase(
      dbPath,
      version: _schemaVersion,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE secure_notes (
            id TEXT PRIMARY KEY,
            title TEXT NOT NULL DEFAULT '',
            preview TEXT NOT NULL DEFAULT '',
            created_at_iso TEXT NOT NULL,
            updated_at_iso TEXT NOT NULL,
            is_pinned INTEGER NOT NULL DEFAULT 0,
            is_deleted INTEGER NOT NULL DEFAULT 0
          )
        ''');
        await db.execute('''
          CREATE TABLE secure_note_blocks (
            id TEXT PRIMARY KEY,
            note_id TEXT NOT NULL,
            type TEXT NOT NULL,
            content_json TEXT NOT NULL,
            plain_text TEXT NOT NULL DEFAULT '',
            order_index INTEGER NOT NULL,
            created_at_iso TEXT NOT NULL,
            updated_at_iso TEXT NOT NULL,
            content_hash TEXT NOT NULL,
            FOREIGN KEY(note_id) REFERENCES secure_notes(id) ON DELETE CASCADE
          )
        ''');
        await db.execute('''
          CREATE TABLE secure_notes_meta (
            key TEXT PRIMARY KEY,
            value TEXT NOT NULL
          )
        ''');
        await _createIndexes(db);
      },
      onOpen: _createIndexes,
    );
  }

  static Future<void> _createIndexes(Database db) async {
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_secure_notes_updated '
      'ON secure_notes(is_deleted, is_pinned, updated_at_iso)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_secure_note_blocks_note_order '
      'ON secure_note_blocks(note_id, order_index)',
    );
  }

  Future<List<SecureNoteRecordDto>> getNotes() async {
    final db = await _database;
    final rows = await db.rawQuery('''
      SELECT n.*,
             COUNT(b.id) AS block_count
      FROM secure_notes n
      LEFT JOIN secure_note_blocks b ON b.note_id = n.id
      WHERE n.is_deleted = 0
      GROUP BY n.id
      ORDER BY n.is_pinned DESC, n.updated_at_iso DESC
    ''');
    return rows.map(SecureNoteRecordDto.fromMap).toList(growable: false);
  }

  Future<List<SecureNoteDetailDto>> getAllNoteDetails() async {
    final summaries = await getNotes();
    final details = <SecureNoteDetailDto>[];
    for (final note in summaries) {
      try {
        details.add(await getNoteById(note.id));
      } catch (_) {
        // A stale note index should not block backup/export.
      }
    }
    return details;
  }

  Future<SecureNoteDetailDto> getNoteById(String id) async {
    final db = await _database;
    final notes = await db.query(
      'secure_notes',
      where: 'id = ? AND is_deleted = 0',
      whereArgs: [id],
      limit: 1,
    );
    if (notes.isEmpty) {
      throw StateError('Secure note not found: $id');
    }
    final blocks = await db.query(
      'secure_note_blocks',
      where: 'note_id = ?',
      whereArgs: [id],
      orderBy: 'order_index ASC',
    );
    return SecureNoteDetailDto(
      note: SecureNoteRecordDto.fromMap({
        ...notes.first,
        'block_count': blocks.length,
      }),
      blocks: blocks
          .map(SecureNoteBlockRecordDto.fromMap)
          .toList(growable: false),
    );
  }

  Future<SecureNoteDetailDto> createNote({
    required String id,
    required String title,
    required String preview,
    required DateTime now,
  }) async {
    final db = await _database;
    await db.insert('secure_notes', {
      'id': id,
      'title': title,
      'preview': preview,
      'created_at_iso': now.toIso8601String(),
      'updated_at_iso': now.toIso8601String(),
      'is_pinned': 0,
      'is_deleted': 0,
    });
    return getNoteById(id);
  }

  Future<void> saveNoteSnapshot(SecureNoteSnapshotEntity snapshot) async {
    final db = await _database;
    final existingBlocks = await db.query(
      'secure_note_blocks',
      where: 'note_id = ?',
      whereArgs: [snapshot.id],
    );
    final existingById = {
      for (final row in existingBlocks)
        '${row['id']}': SecureNoteBlockRecordDto.fromMap(row),
    };
    final incomingIds = snapshot.blocks.map((block) => block.id).toSet();
    final nowIso = snapshot.updatedAt.toIso8601String();

    await db.transaction((txn) async {
      final noteRows = await txn.query(
        'secure_notes',
        columns: const ['title', 'preview', 'updated_at_iso'],
        where: 'id = ?',
        whereArgs: [snapshot.id],
        limit: 1,
      );
      if (noteRows.isEmpty) {
        await txn.insert('secure_notes', {
          'id': snapshot.id,
          'title': snapshot.title,
          'preview': snapshot.preview,
          'created_at_iso': nowIso,
          'updated_at_iso': nowIso,
          'is_pinned': 0,
          'is_deleted': 0,
        });
      } else {
        final row = noteRows.first;
        if (row['title'] != snapshot.title ||
            row['preview'] != snapshot.preview) {
          await txn.update(
            'secure_notes',
            {
              'title': snapshot.title,
              'preview': snapshot.preview,
              'updated_at_iso': nowIso,
            },
            where: 'id = ?',
            whereArgs: [snapshot.id],
          );
        }
      }

      for (final block in snapshot.blocks) {
        final dto = SecureNoteBlockRecordDto.fromEntity(block);
        final existing = existingById[block.id];
        if (existing == null) {
          await txn.insert('secure_note_blocks', dto.toMap());
          continue;
        }
        final shouldUpdate =
            existing.contentHash != block.contentHash ||
            existing.type != block.type ||
            existing.orderIndex != block.orderIndex ||
            existing.plainText != block.plainText ||
            existing.contentJson != block.contentJson;
        if (!shouldUpdate) {
          continue;
        }
        await txn.update(
          'secure_note_blocks',
          dto.toMap(),
          where: 'id = ?',
          whereArgs: [block.id],
        );
      }

      for (final existingId in existingById.keys) {
        if (incomingIds.contains(existingId)) {
          continue;
        }
        await txn.delete(
          'secure_note_blocks',
          where: 'id = ?',
          whereArgs: [existingId],
        );
      }
    });
  }

  Future<void> replaceNoteSnapshots(
    List<Map<String, dynamic>> snapshots,
  ) async {
    final db = await _database;
    await db.transaction((txn) async {
      await txn.delete('secure_note_blocks');
      await txn.delete('secure_notes');
      for (final snapshot in snapshots) {
        final noteRaw = snapshot['note'];
        if (noteRaw is! Map) {
          continue;
        }
        final note = SecureNoteRecordDto.fromMap(
          Map<String, Object?>.from(noteRaw),
        );
        if (note.id.trim().isEmpty) {
          continue;
        }
        await txn.insert('secure_notes', {
          'id': note.id,
          'title': note.title,
          'preview': note.preview,
          'created_at_iso': note.createdAtIso,
          'updated_at_iso': note.updatedAtIso,
          'is_pinned': note.isPinned ? 1 : 0,
          'is_deleted': note.isDeleted ? 1 : 0,
        }, conflictAlgorithm: ConflictAlgorithm.replace);
        final blocksRaw = snapshot['blocks'];
        if (blocksRaw is! List) {
          continue;
        }
        for (final blockRaw in blocksRaw.whereType<Map>()) {
          final block = SecureNoteBlockRecordDto.fromMap(
            Map<String, Object?>.from(blockRaw),
          );
          if (block.id.trim().isEmpty || block.noteId.trim().isEmpty) {
            continue;
          }
          await txn.insert(
            'secure_note_blocks',
            block.toMap(),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
      }
    });
  }

  Future<void> deleteNote(String id) async {
    final db = await _database;
    await db.update(
      'secure_notes',
      {'is_deleted': 1, 'updated_at_iso': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<String?> readMeta(String key) async {
    final db = await _database;
    final rows = await db.query(
      'secure_notes_meta',
      columns: const ['value'],
      where: 'key = ?',
      whereArgs: [key],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return '${rows.first['value']}';
  }

  Future<void> writeMeta(String key, String value) async {
    final db = await _database;
    await db.insert('secure_notes_meta', {
      'key': key,
      'value': value,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }
}

String stableJsonEncode(Object? value) {
  return jsonEncode(value);
}
