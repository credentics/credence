import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pass_doc_manager/data/shared/storage/encrypted_hive_box_factory.dart';
import 'package:pass_doc_manager/features/backup/data/datasources/local/backup_snapshot_builder.dart';
import 'package:pass_doc_manager/features/backup/domain/entities/backup_operation_progress.dart';

/// Restores app state from a backup archive.
class BackupReplayEngine {
  Future<void> restoreFromArchive(
    Map<String, Uint8List> archiveFiles, {
    BackupOperationProgressCallback? onProgress,
  }) async {
    debugPrint('[Replay] Starting restore with ${archiveFiles.length} files');

    _emitProgress(
      onProgress,
      message: 'Restoring encrypted data',
      detail: 'Rebuilding persisted boxes from the backup archive.',
      progress: 0.04,
    );
    await _restoreBoxData(archiveFiles, onProgress: onProgress);

    final pathMapping = await _restoreFileAssets(
      archiveFiles,
      onProgress: onProgress,
    );

    if (pathMapping.isNotEmpty) {
      _emitProgress(
        onProgress,
        message: 'Relinking restored files',
        detail: 'Updating restored records to point at local file paths.',
        progress: 0.92,
      );
      await _rewriteImportedPaths(pathMapping);
    }

    _emitProgress(
      onProgress,
      message: 'Restore complete',
      detail: 'The encrypted data, images, and files are back on this device.',
      progress: 1,
    );
    debugPrint('[Replay] Restore complete');
  }

  Future<void> _restoreBoxData(
    Map<String, Uint8List> archiveFiles, {
    BackupOperationProgressCallback? onProgress,
  }) async {
    // ── Phase 1: decode + validate EVERY box before touching Hive. ──
    // A single corrupt/truncated box entry throws here, before any live box
    // has been cleared, so a bad archive can never leave the vault
    // partially wiped. Nothing is written until the whole archive is known
    // to be well-formed.
    final staged = <String, Map>{};
    for (final boxName in BackupSnapshotBuilder.boxArchiveNames.entries) {
      final bytes = archiveFiles['data/${boxName.value}.json'];
      if (bytes == null) {
        debugPrint('[Replay] No data for ${boxName.key}, skipping');
        continue;
      }
      final Object? rawData;
      try {
        rawData = jsonDecode(utf8.decode(bytes));
      } catch (e) {
        debugPrint('[Replay] Corrupt archive for ${boxName.key}: $e');
        throw FormatException(
          'Backup archive is corrupt (box "${boxName.value}") — '
          'restore aborted before any local data was changed.',
        );
      }
      if (rawData is! Map) {
        throw FormatException(
          'Backup archive has an unexpected shape for box '
          '"${boxName.value}" — restore aborted before any change.',
        );
      }
      staged[boxName.key] = rawData;
    }

    // ── Phase 2: every staged box is well-formed — apply them. ──
    // Even though the archive is validated, a write can still fail mid-way
    // (e.g. disk full). We snapshot each box's current contents just before
    // clearing it and, on any failure, roll every already-touched box back to
    // its pre-restore state so the vault is never left half-restored.
    final total = staged.length;
    var processed = 0;
    final rollback = <String, Map<dynamic, dynamic>>{};
    try {
      for (final entry in staged.entries) {
        final box = await EncryptedHiveBoxFactory.openEncryptedBox(entry.key);
        // Capture current state before mutating, keyed for rollback.
        rollback[entry.key] = {
          for (final k in box.keys) k: box.get(k),
        };

        await box.clear();
        for (final kv in entry.value.entries) {
          await box.put(kv.key, kv.value);
        }

        processed += 1;
        _emitProgress(
          onProgress,
          message: 'Restoring encrypted data',
          detail: total == 0
              ? 'No persisted boxes were found in the archive.'
              : 'Restored $processed of $total encrypted boxes.',
          progress: total == 0 ? 0.42 : 0.04 + ((processed / total) * 0.38),
          processedCount: processed,
          totalCount: total,
        );
        debugPrint(
          '[Replay] Restored ${entry.key}: ${entry.value.length} keys',
        );
      }
    } catch (e) {
      debugPrint('[Replay] Restore failed ($e) — rolling back ${rollback.length} boxes');
      for (final entry in rollback.entries) {
        try {
          final box = await EncryptedHiveBoxFactory.openEncryptedBox(entry.key);
          await box.clear();
          for (final kv in entry.value.entries) {
            await box.put(kv.key, kv.value);
          }
        } catch (rollbackError) {
          debugPrint('[Replay] Rollback of ${entry.key} failed: $rollbackError');
        }
      }
      rethrow;
    }
  }

  Future<Map<String, String>> _restoreFileAssets(
    Map<String, Uint8List> archiveFiles, {
    BackupOperationProgressCallback? onProgress,
  }) async {
    final supportDir = await getApplicationSupportDirectory();
    final fileEntries = archiveFiles.entries
        .where((entry) => entry.key.startsWith('files/'))
        .toList(growable: false);
    final total = fileEntries.length;
    var restoredCount = 0;
    final pathMapping = <String, String>{};

    if (total == 0) {
      _emitProgress(
        onProgress,
        message: 'Restoring local files',
        detail: 'No local images or attachments were found in the backup.',
        progress: 0.88,
      );
      return pathMapping;
    }

    for (final entry in fileEntries) {
      final relativePath = entry.key.substring('files/'.length);
      final targetPath =
          '${supportDir.path}${Platform.pathSeparator}$relativePath';

      try {
        final targetFile = File(targetPath);
        await targetFile.parent.create(recursive: true);
        await targetFile.writeAsBytes(entry.value, flush: true);
        pathMapping[entry.key] = targetPath;
        pathMapping[relativePath] = targetPath;
        restoredCount += 1;
      } on FileSystemException catch (e) {
        if (e.message.contains('No space') || e.osError?.errorCode == 28) {
          throw StateError(
            'Not enough disk space to restore. Free up storage and try again.',
          );
        }
        debugPrint('[Replay] Error restoring file $relativePath: $e');
      } catch (e) {
        debugPrint('[Replay] Error restoring file $relativePath: $e');
      }

      _emitProgress(
        onProgress,
        message: 'Restoring local files',
        detail: 'Restored $restoredCount of $total local files.',
        progress: 0.48 + ((restoredCount / total) * 0.4),
        processedCount: restoredCount,
        totalCount: total,
        fileCount: total,
      );
    }

    debugPrint('[Replay] Restored $restoredCount file assets');
    return pathMapping;
  }

  Future<void> applyDeltaJournal(Map<String, Uint8List> deltaFiles) async {
    final journalBytes = deltaFiles['data/journal.json'];
    if (journalBytes == null) {
      debugPrint('[Replay] No journal in delta, only applying files');
      await _restoreFileAssets(deltaFiles);
      return;
    }

    final journalJson = jsonDecode(utf8.decode(journalBytes));
    if (journalJson is! List) {
      return;
    }

    debugPrint('[Replay] Applying ${journalJson.length} journal entries');
    for (final entry in journalJson) {
      if (entry is! Map) {
        continue;
      }
      final operation = entry['operation'] as String? ?? '';
      final entityType = entry['entity_type'] as String? ?? '';
      final entityData = entry['entity_data'];

      if (entityData == null && operation != 'delete') {
        continue;
      }

      final boxName = _boxForEntityType(entityType);
      if (boxName == null) {
        continue;
      }

      final box = await EncryptedHiveBoxFactory.openEncryptedBox(boxName);
      final entityId = entry['entity_id'] as String? ?? '';

      switch (operation) {
        case 'create':
        case 'update':
        case 'move':
        case 'restore':
          if (boxName == 'credence_collections_v1') {
            await _applyCollectionChange(box, entityId, entityData, operation);
          } else {
            await box.put(entityId, entityData);
          }
        case 'delete':
          if (boxName == 'credence_collections_v1') {
            await _applyCollectionDelete(box, entityId);
          } else {
            await box.delete(entityId);
          }
      }
    }

    await _restoreFileAssets(deltaFiles);
  }

  Future<void> _rewriteImportedPaths(Map<String, String> pathMapping) async {
    final docsBox = await EncryptedHiveBoxFactory.openEncryptedBox(
      'credence_documents_v1',
    );
    final credsBox = await EncryptedHiveBoxFactory.openEncryptedBox(
      'credence_credentials_v1',
    );
    final collectionsBox = await EncryptedHiveBoxFactory.openEncryptedBox(
      'credence_collections_v1',
    );
    final profileBox = await EncryptedHiveBoxFactory.openEncryptedBox(
      'credence_profile_v1',
    );

    for (final key in docsBox.keys.toList()) {
      final raw = docsBox.get(key);
      if (raw is! Map) {
        continue;
      }
      final doc = Map<String, dynamic>.from(raw);
      var changed = false;

      if (doc['structuredFields'] is List) {
        final fields = (doc['structuredFields'] as List)
            .map(
              (field) =>
                  field is Map ? Map<String, dynamic>.from(field) : field,
            )
            .toList();
        for (var i = 0; i < fields.length; i++) {
          if (fields[i] is! Map<String, dynamic>) {
            continue;
          }
          final field = fields[i] as Map<String, dynamic>;
          final value = (field['value'] ?? '').toString();
          if (value.isEmpty) {
            continue;
          }

          if (value.startsWith('[')) {
            final rewritten = _rewriteJsonArrayPaths(value, pathMapping);
            if (rewritten != value) {
              field['value'] = rewritten;
              changed = true;
            }
          } else {
            final mapped = _findMappedPath(value, pathMapping);
            if (mapped != null) {
              field['value'] = mapped;
              changed = true;
            }
          }
        }
        if (changed) {
          doc['structuredFields'] = fields;
        }
      }

      if (changed) {
        await docsBox.put(key, doc);
      }
    }

    for (final key in credsBox.keys.toList()) {
      final raw = credsBox.get(key);
      if (raw is! Map) {
        continue;
      }
      final cred = Map<String, dynamic>.from(raw);
      final logoPath = (cred['logoPath'] ?? '').toString();
      if (logoPath.isEmpty) {
        continue;
      }
      final mapped = _findMappedPath(logoPath, pathMapping);
      if (mapped != null) {
        cred['logoPath'] = mapped;
        await credsBox.put(key, cred);
      }
    }

    for (final key in collectionsBox.keys.toList()) {
      final raw = collectionsBox.get(key);
      if (raw is! Map) {
        continue;
      }
      final collection = Map<String, dynamic>.from(raw);
      var changed = false;

      for (final field in [
        'cover_image_url',
        'coverImageUrl',
        'icon_image_path',
        'iconImagePath',
      ]) {
        final value = (collection[field] ?? '').toString();
        if (value.isEmpty) {
          continue;
        }
        final mapped = _findMappedPath(value, pathMapping);
        if (mapped != null) {
          collection[field] = mapped;
          changed = true;
        }
      }

      if (collection['blocks'] is List) {
        final blocks = (collection['blocks'] as List)
            .map(
              (block) =>
                  block is Map ? Map<String, dynamic>.from(block) : block,
            )
            .toList();
        for (var i = 0; i < blocks.length; i++) {
          if (blocks[i] is! Map<String, dynamic>) {
            continue;
          }
          final block = blocks[i] as Map<String, dynamic>;
          for (final field in [
            'image_url',
            'imageUrl',
            'file_path',
            'filePath',
          ]) {
            final value = (block[field] ?? '').toString();
            if (value.isEmpty) {
              continue;
            }
            final mapped = _findMappedPath(value, pathMapping);
            if (mapped != null) {
              block[field] = mapped;
              changed = true;
            }
          }

          if (block['metadata'] is Map) {
            final metadata = Map<String, dynamic>.from(
              block['metadata'] as Map,
            );
            var metadataChanged = false;
            for (final key in metadata.keys.toList()) {
              final value = (metadata[key] ?? '').toString();
              if (value.isEmpty) {
                continue;
              }

              if (value.startsWith('[')) {
                final rewritten = _rewriteJsonArrayPaths(value, pathMapping);
                if (rewritten != value) {
                  metadata[key] = rewritten;
                  metadataChanged = true;
                }
              } else {
                final mapped = _findMappedPath(value, pathMapping);
                if (mapped != null) {
                  metadata[key] = mapped;
                  metadataChanged = true;
                }
              }
            }
            if (metadataChanged) {
              block['metadata'] = metadata;
              changed = true;
            }
          }
        }
        if (changed) {
          collection['blocks'] = blocks;
        }
      }

      if (changed) {
        await collectionsBox.put(key, collection);
      }
    }

    final rawProfile = profileBox.get('profile_record');
    if (rawProfile is Map) {
      final profile = Map<String, dynamic>.from(rawProfile);
      final photoPath = (profile['photoPath'] ?? '').toString();
      if (photoPath.isNotEmpty) {
        final mapped = _findMappedPath(photoPath, pathMapping);
        if (mapped != null) {
          profile['photoPath'] = mapped;
          await profileBox.put('profile_record', profile);
        }
      }
    }
  }

  String? _findMappedPath(String archivePath, Map<String, String> mapping) {
    if (mapping.containsKey(archivePath)) {
      return mapping[archivePath];
    }
    final trimmed = archivePath.startsWith('/')
        ? archivePath.substring(1)
        : archivePath;
    if (mapping.containsKey(trimmed)) {
      return mapping[trimmed];
    }
    final fileName = archivePath.split('/').last;
    for (final entry in mapping.entries) {
      if (entry.key.endsWith('/$fileName') || entry.key == fileName) {
        return entry.value;
      }
    }
    return null;
  }

  String _rewriteJsonArrayPaths(
    String jsonString,
    Map<String, String> mapping,
  ) {
    try {
      final decoded = jsonDecode(jsonString);
      if (decoded is! List) {
        return jsonString;
      }
      var changed = false;
      final rewritten = decoded.map((item) {
        if (item is! Map) {
          return item;
        }
        final path = (item['path'] ?? '').toString();
        if (path.isEmpty) {
          return item;
        }
        final mapped = _findMappedPath(path, mapping);
        if (mapped != null) {
          changed = true;
          return {...item, 'path': mapped};
        }
        return item;
      }).toList();
      return changed ? jsonEncode(rewritten) : jsonString;
    } catch (_) {
      return jsonString;
    }
  }

  // Collections are stored as nested trees (blocks/metadata), so a journal
  // entry cannot be replayed as a flat box.put/delete the way flat entities
  // can. Rather than silently discard the change (which loses collection data
  // while reporting success), these fail loud: the delta path must not be
  // wired up for collections until real tree-merge replay is implemented.
  // Full-snapshot restore (restoreFromArchive) handles collections correctly.
  Future<void> _applyCollectionChange(
    dynamic box,
    String entityId,
    dynamic entityData,
    String operation,
  ) async {
    throw UnsupportedError(
      'Collection delta replay is not implemented ($operation on $entityId). '
      'Use a full-snapshot restore for collections.',
    );
  }

  Future<void> _applyCollectionDelete(dynamic box, String entityId) async {
    throw UnsupportedError(
      'Collection delta delete is not implemented ($entityId). '
      'Use a full-snapshot restore for collections.',
    );
  }

  String? _boxForEntityType(String entityType) {
    if (entityType.contains('credential')) {
      return 'credence_credentials_v1';
    }
    if (entityType.contains('document')) {
      return 'credence_documents_v1';
    }
    if (entityType.contains('collection')) {
      return 'credence_collections_v1';
    }
    if (entityType.contains('profile')) {
      return 'credence_profile_v1';
    }
    if (entityType.contains('password_history')) {
      return 'credence_generator_history_v1';
    }
    return null;
  }

  void _emitProgress(
    BackupOperationProgressCallback? onProgress, {
    required String message,
    required String detail,
    double? progress,
    int? processedCount,
    int? totalCount,
    int? fileCount,
  }) {
    onProgress?.call(
      BackupOperationProgress(
        message: message,
        detail: detail,
        progress: progress,
        processedCount: processedCount,
        totalCount: totalCount,
        fileCount: fileCount,
      ),
    );
  }
}
