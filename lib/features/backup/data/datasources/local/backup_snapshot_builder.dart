import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';
import 'package:pass_doc_manager/data/shared/storage/encrypted_hive_box_factory.dart';
import 'package:pass_doc_manager/features/backup/domain/entities/backup_operation_progress.dart';

class BackupSnapshotResult {
  const BackupSnapshotResult({
    required this.archiveFiles,
    required this.entityCount,
    required this.fileCount,
  });

  final Map<String, Uint8List> archiveFiles;
  final int entityCount;
  final int fileCount;
}

/// Reads the persisted app state into an archive-ready map.
///
/// The snapshot includes every encrypted Hive box used by the app plus the
/// full application-support storage tree, excluding only transient backup
/// working directories and previously generated local backup archives.
class BackupSnapshotBuilder {
  static const _boxNames = [
    'credence_credentials_v1',
    'credence_documents_v1',
    'credence_collections_v1',
    'credence_bundles_v1',
    'credence_tasks_v1',
    'credence_profile_v1',
    'credence_backup_journal_v1',
    'credence_generator_history_v1',
    'credence_home_prefs_v1',
    'credence_passwords_v1',
    'credence_sync_prefs_v1',
    'credence_notification_settings_v1',
  ];

  static const boxArchiveNames = {
    'credence_credentials_v1': 'credentials',
    'credence_documents_v1': 'documents',
    'credence_collections_v1': 'collections',
    'credence_bundles_v1': 'bundles',
    'credence_tasks_v1': 'tasks',
    'credence_profile_v1': 'profile',
    'credence_backup_journal_v1': 'backup_journal',
    'credence_generator_history_v1': 'password_history',
    'credence_home_prefs_v1': 'home_prefs',
    'credence_passwords_v1': 'legacy_passwords',
    'credence_sync_prefs_v1': 'sync_prefs',
    'credence_notification_settings_v1': 'notification_settings',
  };

  static const _excludedRootDirectories = <String>{
    'backup_temp',
    'local_backups',
    'restore_rollback',
    'restore_staging',
  };

  Future<BackupSnapshotResult> buildFullSnapshot({
    BackupOperationProgressCallback? onProgress,
  }) async {
    final archive = <String, Uint8List>{};
    var entityCount = 0;

    _emitProgress(
      onProgress,
      message: 'Reading encrypted data',
      detail: 'Collecting every persisted Hive box used by the vault.',
      progress: 0.04,
      processedCount: 0,
      totalCount: _boxNames.length,
    );

    var processedBoxes = 0;
    for (final boxName in _boxNames) {
      final box = await EncryptedHiveBoxFactory.openEncryptedBox(boxName);
      final archiveName = boxArchiveNames[boxName] ?? boxName;
      final rawData = <String, dynamic>{};

      for (final key in box.keys) {
        rawData['$key'] = box.get(key);
      }

      entityCount += rawData.length;
      archive['data/$archiveName.json'] = _encodeJson(rawData);
      processedBoxes += 1;
      _emitProgress(
        onProgress,
        message: 'Reading encrypted data',
        detail:
            'Captured $processedBoxes of ${_boxNames.length} persisted boxes.',
        progress: 0.04 + ((processedBoxes / _boxNames.length) * 0.36),
        processedCount: processedBoxes,
        totalCount: _boxNames.length,
        entityCount: entityCount,
      );
    }

    _emitProgress(
      onProgress,
      message: 'Scanning local files',
      detail: 'Walking the app storage tree to find images and attachments.',
      progress: 0.44,
      entityCount: entityCount,
    );
    final supportFiles = await _collectRestorableFiles();
    final fileCount = supportFiles.length;

    if (fileCount == 0) {
      _emitProgress(
        onProgress,
        message: 'Scanning local files',
        detail: 'No restorable local files were found in app storage.',
        progress: 0.58,
        entityCount: entityCount,
        fileCount: 0,
      );
      return BackupSnapshotResult(
        archiveFiles: archive,
        entityCount: entityCount,
        fileCount: 0,
      );
    }

    _emitProgress(
      onProgress,
      message: 'Packaging local files',
      detail: 'Copying images, PDFs, attachments, and saved assets.',
      progress: 0.52,
      processedCount: 0,
      totalCount: fileCount,
      entityCount: entityCount,
      fileCount: fileCount,
    );

    var processedFiles = 0;
    for (final descriptor in supportFiles) {
      try {
        final bytes = await File(descriptor.sourcePath).readAsBytes();
        archive['files/${descriptor.relativePath}'] = bytes;
      } catch (_) {
        // Skip unreadable files and continue with the rest of the snapshot.
      }

      processedFiles += 1;
      _emitProgress(
        onProgress,
        message: 'Packaging local files',
        detail: 'Included $processedFiles of $fileCount local files.',
        progress: 0.52 + ((processedFiles / fileCount) * 0.48),
        processedCount: processedFiles,
        totalCount: fileCount,
        entityCount: entityCount,
        fileCount: fileCount,
      );
    }

    return BackupSnapshotResult(
      archiveFiles: archive,
      entityCount: entityCount,
      fileCount: fileCount,
    );
  }

  Future<List<_SupportFileDescriptor>> _collectRestorableFiles() async {
    final supportDir = await getApplicationSupportDirectory();
    if (!await supportDir.exists()) {
      return const <_SupportFileDescriptor>[];
    }

    final basePath = supportDir.path.replaceAll('\\', '/');
    final files = <_SupportFileDescriptor>[];

    await for (final entity in supportDir.list(
      recursive: true,
      followLinks: false,
    )) {
      if (entity is! File) {
        continue;
      }

      final normalizedSource = entity.path.replaceAll('\\', '/');
      if (!normalizedSource.startsWith('$basePath/')) {
        continue;
      }

      final relativePath = normalizedSource.substring(basePath.length + 1);
      final normalizedRelative = _normalizeArchiveRelativePath(relativePath);
      if (normalizedRelative == null ||
          _shouldSkipRelativePath(normalizedRelative)) {
        continue;
      }

      files.add(
        _SupportFileDescriptor(
          sourcePath: entity.path,
          relativePath: normalizedRelative,
        ),
      );
    }

    files.sort((a, b) => a.relativePath.compareTo(b.relativePath));
    return files;
  }

  bool _shouldSkipRelativePath(String relativePath) {
    final segments = relativePath.split('/');
    if (segments.isEmpty) {
      return true;
    }
    return _excludedRootDirectories.contains(segments.first);
  }

  String? _normalizeArchiveRelativePath(String relativePath) {
    final parts = relativePath
        .split('/')
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty && item != '.' && item != '..')
        .map(_sanitizeArchiveSegment)
        .toList(growable: false);
    if (parts.isEmpty) {
      return null;
    }
    return parts.join('/');
  }

  Uint8List _encodeJson(Object? data) {
    return Uint8List.fromList(utf8.encode(jsonEncode(data ?? {})));
  }

  void _emitProgress(
    BackupOperationProgressCallback? onProgress, {
    required String message,
    required String detail,
    double? progress,
    int? processedCount,
    int? totalCount,
    int? entityCount,
    int? fileCount,
  }) {
    onProgress?.call(
      BackupOperationProgress(
        message: message,
        detail: detail,
        progress: progress,
        processedCount: processedCount,
        totalCount: totalCount,
        entityCount: entityCount,
        fileCount: fileCount,
      ),
    );
  }
}

class _SupportFileDescriptor {
  const _SupportFileDescriptor({
    required this.sourcePath,
    required this.relativePath,
  });

  final String sourcePath;
  final String relativePath;
}

String _sanitizeArchiveSegment(String input) {
  final compact = input.trim();
  if (compact.isEmpty) {
    return 'file.bin';
  }
  final sanitized = compact.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
  if (sanitized.isEmpty) {
    return 'file.bin';
  }
  return sanitized;
}
