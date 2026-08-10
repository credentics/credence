import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';
import 'dart:math' as math;

import 'package:cryptography/cryptography.dart';
import 'package:dio/dio.dart';
import 'package:pass_doc_manager/data/vault_sync/mirror/vault_mirror_workspace.dart';
import 'package:pass_doc_manager/domain/vault_sync/entities/vault_sync_head_entity.dart';
import 'package:pass_doc_manager/domain/vault_sync/entities/vault_sync_operation_entity.dart';
import 'package:pass_doc_manager/domain/vault_sync/entities/vault_sync_progress_entity.dart';

class DropboxFileMetadata {
  const DropboxFileMetadata({
    required this.pathLower,
    required this.rev,
    required this.contentHash,
  });

  final String pathLower;
  final String rev;
  final String contentHash;
}

class DropboxSyncHeadReadResult {
  const DropboxSyncHeadReadResult({required this.head, required this.rev});

  final VaultSyncHeadEntity head;
  final String rev;
}

class DropboxMirrorDataSource {
  const DropboxMirrorDataSource({required this.dio});

  final Dio dio;

  static const int _singleUploadLimitBytes = 140 * 1024 * 1024;
  static const int _chunkSizeBytes = 8 * 1024 * 1024;
  static const String _syncRootPath = VaultMirrorWorkspace.syncDir;
  static const int _operationBatchThreshold = 20;
  static const Duration _connectTimeout = Duration(seconds: 8);
  static const Duration _metadataTimeout = Duration(seconds: 15);
  static const Duration _downloadTimeout = Duration(seconds: 20);
  static const Duration _uploadTimeout = Duration(seconds: 60);

  bool get supportsPassiveCheck => true;

  int get estimatedPassiveCheckCost => 2048;

  Future<VaultSyncHeadEntity?> readHead({
    required String accessToken,
    required String directoryPath,
  }) async {
    final stopwatch = Stopwatch()..start();
    var bytesRead = 0;
    final rootPath = _normalizeRoot(directoryPath);
    final bytes = await _downloadBytesOrNull(
      accessToken: accessToken,
      remotePath: _remotePath(rootPath, VaultMirrorWorkspace.headPath),
    );
    if (bytes != null) {
      bytesRead += bytes.length;
      stopwatch.stop();
      developer.log(
        '[DropboxPassiveCheck] Read head.json (${bytes.length} bytes) '
        'in ${stopwatch.elapsedMilliseconds}ms',
        name: 'DropboxMirror',
      );
      return VaultSyncHeadEntity.fromJsonText(utf8.decode(bytes));
    }

    final fallback = await _downloadBytesOrNull(
      accessToken: accessToken,
      remotePath: _remotePath(rootPath, VaultMirrorWorkspace.manifestPath),
    );
    stopwatch.stop();
    if (fallback == null) {
      developer.log(
        '[DropboxPassiveCheck] No head.json or manifest.json found '
        'in ${stopwatch.elapsedMilliseconds}ms',
        name: 'DropboxMirror',
      );
      return null;
    }
    bytesRead += fallback.length;
    developer.log(
      '[DropboxPassiveCheck] head.json missing; read manifest fallback '
      '($bytesRead bytes) in ${stopwatch.elapsedMilliseconds}ms',
      name: 'DropboxMirror',
    );
    final manifestText = utf8.decode(fallback);
    final manifest = VaultMirrorManifest.fromJsonText(manifestText);
    if (manifest.revision <= 0) {
      return null;
    }
    return VaultSyncHeadEntity(
      revision: manifest.revision,
      deviceId: manifest.deviceId,
      manifestHash: manifest.contentChecksum.isNotEmpty
          ? manifest.contentChecksum
          : await _hashBytes(fallback),
      generatedAtIso: manifest.generatedAtIso,
      provider: 'dropbox',
      fileCount: manifest.filesByPath.length,
      directoryCount: manifest.managedDirectories.length,
    );
  }

  Future<VaultSyncHeadEntity?> readManifestHeadFallback({
    required String accessToken,
    required String directoryPath,
  }) async {
    final rootPath = _normalizeRoot(directoryPath);
    final bytes = await _downloadBytesOrNull(
      accessToken: accessToken,
      remotePath: _remotePath(rootPath, VaultMirrorWorkspace.manifestPath),
    );
    if (bytes == null) {
      return null;
    }
    final manifestText = utf8.decode(bytes);
    final manifest = VaultMirrorManifest.fromJsonText(manifestText);
    if (manifest.revision <= 0) {
      return null;
    }
    return VaultSyncHeadEntity(
      revision: manifest.revision,
      deviceId: manifest.deviceId,
      manifestHash: manifest.contentChecksum.isNotEmpty
          ? manifest.contentChecksum
          : await _hashBytes(bytes),
      generatedAtIso: manifest.generatedAtIso,
      provider: 'dropbox',
      fileCount: manifest.filesByPath.length,
      directoryCount: manifest.managedDirectories.length,
    );
  }

  Future<void> writeHead({
    required String accessToken,
    required String directoryPath,
    required VaultSyncHeadEntity head,
  }) async {
    final rootPath = _normalizeRoot(directoryPath);
    await _uploadBytes(
      accessToken: accessToken,
      remotePath: _remotePath(rootPath, VaultMirrorWorkspace.headPath),
      bytes: utf8.encode(head.toJsonText()),
    );
  }

  Future<DropboxSyncHeadReadResult?> readProtocolHead({
    required String accessToken,
    required String directoryPath,
  }) async {
    final rootPath = _normalizeRoot(directoryPath);
    final remotePath = _remotePath(rootPath, '$_syncRootPath/head.json');
    final metadata = await _getMetadataOrNull(
      accessToken: accessToken,
      remotePath: remotePath,
    );
    if (metadata == null || metadata.rev.isEmpty) {
      return null;
    }
    final bytes = await _downloadBytesOrNull(
      accessToken: accessToken,
      remotePath: remotePath,
    );
    if (bytes == null) {
      return null;
    }
    return DropboxSyncHeadReadResult(
      head: VaultSyncHeadEntity.fromJsonText(utf8.decode(bytes)),
      rev: metadata.rev,
    );
  }

  Future<List<VaultSyncOperationEntity>> readProtocolOperations({
    required String accessToken,
    required String directoryPath,
    Set<String> knownOperationIds = const <String>{},
  }) async {
    final rootPath = _normalizeRoot(directoryPath);
    final files = await _listFilesRecursive(
      accessToken: accessToken,
      remotePath: _remotePath(rootPath, '$_syncRootPath/ops'),
    );
    final batchFiles = await _listFilesRecursive(
      accessToken: accessToken,
      remotePath: _remotePath(rootPath, '$_syncRootPath/op_batches'),
    );
    final knownFileIds = knownOperationIds
        .map(_safePathSegment)
        .where((id) => id.isNotEmpty)
        .toSet();
    final operations = <VaultSyncOperationEntity>[];
    final operationPaths = files
        .where((path) => path.endsWith('.json'))
        .where(
          (path) => !knownFileIds.contains(_operationIdFromFilePath(path)),
        );
    for (final path in operationPaths) {
      final bytes = await _downloadBytesOrNull(
        accessToken: accessToken,
        remotePath: path,
      );
      if (bytes == null) {
        continue;
      }
      try {
        final decoded = _decodeProtocolOperationFile(bytes);
        for (final operation in decoded) {
          if (!knownOperationIds.contains(operation.opId)) {
            operations.add(operation);
          }
        }
      } catch (_) {
        // Ignore corrupted operation files; mirror import remains the fallback.
      }
    }
    for (final path in batchFiles.where((path) => path.endsWith('.json'))) {
      final bytes = await _downloadBytesOrNull(
        accessToken: accessToken,
        remotePath: path,
      );
      if (bytes == null) {
        continue;
      }
      try {
        final decoded = _decodeProtocolOperationFile(bytes);
        for (final operation in decoded) {
          if (!knownOperationIds.contains(operation.opId)) {
            operations.add(operation);
          }
        }
      } catch (_) {
        // Ignore corrupted operation batches; mirror import remains fallback.
      }
    }
    operations.sort((a, b) {
      final byDevice = a.deviceId.compareTo(b.deviceId);
      if (byDevice != 0) return byDevice;
      return a.sequence.compareTo(b.sequence);
    });
    return operations;
  }

  Future<void> writeProtocolOperations({
    required String accessToken,
    required String directoryPath,
    required List<VaultSyncOperationEntity> operations,
  }) async {
    if (operations.isEmpty) {
      return;
    }
    final rootPath = _normalizeRoot(directoryPath);
    await _ensureSyncFolders(
      accessToken: accessToken,
      rootPath: rootPath,
      deviceIds: operations.map((operation) => operation.deviceId).toSet(),
    );
    if (operations.length >= _operationBatchThreshold) {
      await _writeProtocolOperationBatch(
        accessToken: accessToken,
        rootPath: rootPath,
        operations: operations,
      );
      return;
    }
    for (final operation in operations) {
      final remotePath = _remotePath(
        rootPath,
        '$_syncRootPath/ops/${_safePathSegment(operation.deviceId)}/'
        '${operation.sequence.toString().padLeft(12, '0')}_${_safePathSegment(operation.opId)}.json',
      );
      if (await _getMetadataOrNull(
            accessToken: accessToken,
            remotePath: remotePath,
          ) !=
          null) {
        continue;
      }
      await _uploadBytes(
        accessToken: accessToken,
        remotePath: remotePath,
        bytes: utf8.encode(operation.toJsonText()),
        mode: 'add',
        strictConflict: true,
      );
    }
  }

  Future<void> _writeProtocolOperationBatch({
    required String accessToken,
    required String rootPath,
    required List<VaultSyncOperationEntity> operations,
  }) async {
    final sorted = operations.toList(growable: false)
      ..sort((a, b) {
        final byDevice = a.deviceId.compareTo(b.deviceId);
        if (byDevice != 0) return byDevice;
        return a.sequence.compareTo(b.sequence);
      });
    final first = sorted.first;
    final last = sorted.last;
    final deviceId = sorted
        .map((operation) => operation.deviceId)
        .where((id) => id.trim().isNotEmpty)
        .toSet()
        .join('_');
    final batchId = await _hashBytes(
      utf8.encode(sorted.map((operation) => operation.opId).join('|')),
    );
    final remotePath = _remotePath(
      rootPath,
      '$_syncRootPath/op_batches/${_safePathSegment(deviceId)}/'
      '${first.sequence.toString().padLeft(12, '0')}_'
      '${last.sequence.toString().padLeft(12, '0')}_'
      '${batchId.substring(0, math.min(12, batchId.length))}.json',
    );
    final payload = {
      'schema_version': 1,
      'kind': 'vault_sync_operation_batch',
      'device_id': deviceId,
      'first_sequence': first.sequence,
      'last_sequence': last.sequence,
      'operation_count': sorted.length,
      'operations': sorted
          .map((operation) => operation.toMap(includeLocalState: false))
          .toList(growable: false),
    };
    await _uploadBytes(
      accessToken: accessToken,
      remotePath: remotePath,
      bytes: utf8.encode(const JsonEncoder.withIndent('  ').convert(payload)),
      mode: 'overwrite',
    );
  }

  List<VaultSyncOperationEntity> _decodeProtocolOperationFile(List<int> bytes) {
    final decoded = jsonDecode(utf8.decode(bytes));
    if (decoded is! Map) {
      throw const FormatException('Sync protocol file must be a JSON object.');
    }
    final operations = decoded['operations'];
    if (operations is List) {
      return operations
          .whereType<Map>()
          .map(
            (operation) => VaultSyncOperationEntity.fromMap(
              Map<String, dynamic>.from(operation),
            ),
          )
          .toList(growable: false);
    }
    return [
      VaultSyncOperationEntity.fromMap(Map<String, dynamic>.from(decoded)),
    ];
  }

  Future<String?> writeProtocolHead({
    required String accessToken,
    required String directoryPath,
    required VaultSyncHeadEntity head,
    String? expectedRev,
  }) async {
    final rootPath = _normalizeRoot(directoryPath);
    await _ensureSyncFolders(accessToken: accessToken, rootPath: rootPath);
    final result = await _uploadBytes(
      accessToken: accessToken,
      remotePath: _remotePath(rootPath, '$_syncRootPath/head.json'),
      bytes: utf8.encode(head.toJsonText()),
      mode: expectedRev == null || expectedRev.isEmpty
          ? 'add'
          : {'.tag': 'update', 'update': expectedRev},
      strictConflict: true,
    );
    return '${result?['rev'] ?? ''}'.trim();
  }

  Future<VaultMirrorResult> writeWorkspace({
    required String accessToken,
    required String directoryPath,
    required VaultMirrorWorkspace workspace,
    bool metadataOnly = false,
    Set<String>? allowedChangedFilePaths,
    Set<String>? allowedDeletedFilePaths,
    VaultSyncProgressCallback? onProgress,
  }) async {
    final rootPath = _normalizeRoot(directoryPath);
    _emitProgress(
      onProgress,
      message: 'Connecting to Dropbox',
      detail: 'Ensuring the remote root folder exists at $rootPath.',
      progress: 0.12,
      totalCount: workspace.fileCount + workspace.directoryCount + 1,
      entityCount: workspace.nodeCount,
      fileCount: workspace.fileCount,
    );
    await _createFolder(
      accessToken: accessToken,
      remotePath: rootPath,
      allowExisting: true,
    );
    final previous = await _readManifest(
      accessToken: accessToken,
      rootPath: rootPath,
    );
    final nextFilePaths =
        workspace.files.map((file) => file.relativePath).toSet()
          ..add(VaultMirrorWorkspace.manifestPath)
          ..add(VaultMirrorWorkspace.headPath);
    final staleFiles = previous.managedFiles
        .where((path) => !nextFilePaths.contains(path))
        .where(
          (path) =>
              allowedDeletedFilePaths == null ||
              allowedDeletedFilePaths.contains(path),
        )
        .toList(growable: false);
    final changedFiles = workspace.files
        .where(
          (file) =>
              previous.fileHashesByPath[file.relativePath] != file.contentHash,
        )
        .where(
          (file) =>
              _isMirrorMetadataFile(file.relativePath) ||
              allowedChangedFilePaths == null ||
              allowedChangedFilePaths.contains(file.relativePath),
        )
        .toList(growable: false);
    final requiredDirectories = _requiredDirectoriesForFiles(changedFiles)
      ..addAll(_parentDirectories(VaultMirrorWorkspace.manifestPath));
    final staleDirectories = const <String>[];
    final totalSteps =
        staleFiles.length +
        requiredDirectories.length +
        changedFiles.length +
        staleDirectories.length +
        1;
    var processedSteps = 0;

    _emitProgress(
      onProgress,
      message: 'Planning Dropbox mirror',
      detail: metadataOnly
          ? 'Backup metadata needs an update. ${_countLabel(requiredDirectories.length, 'folder')} needed.'
          : '${_countLabel(changedFiles.length, 'changed mirror file')}, ${_countLabel(requiredDirectories.length, 'folder')} needed, ${_countLabel(staleFiles.length, 'stale file')} to remove.',
      progress: 0.16,
      processedCount: processedSteps,
      totalCount: totalSteps,
      entityCount: workspace.nodeCount,
      fileCount: workspace.fileCount,
    );

    // NOTE: stale files are deleted AFTER the manifest is uploaded (see below),
    // not here. Deleting first would, on a crash mid-write, leave the old
    // manifest referencing files that no longer exist. By deleting last, the
    // committed manifest always describes a fully-present file set; the worst a
    // crash can leave is harmless orphan files, which the next write cleans up.

    final directories = requiredDirectories.toList(growable: false)
      ..sort((a, b) => a.length.compareTo(b.length));

    _emitProgress(
      onProgress,
      message: 'Creating Dropbox folders',
      detail: 'Verifying folders needed by changed files.',
      progress: 0.24,
      processedCount: processedSteps,
      totalCount: totalSteps,
      entityCount: workspace.nodeCount,
      fileCount: workspace.fileCount,
    );
    for (final directory in directories) {
      _emitProgress(
        onProgress,
        message: 'Creating Dropbox folders',
        detail: 'Ensuring $directory exists.',
        progress: _stepProgress(processedSteps, totalSteps, 0.24, 0.38),
        processedCount: processedSteps,
        totalCount: totalSteps,
        entityCount: workspace.nodeCount,
        fileCount: workspace.fileCount,
      );
      await _createFolder(
        accessToken: accessToken,
        remotePath: _remotePath(rootPath, directory),
        allowExisting: true,
      );
      processedSteps += 1;
    }

    for (final file in changedFiles) {
      _emitProgress(
        onProgress,
        message: metadataOnly
            ? 'Uploading backup metadata'
            : 'Uploading Dropbox files',
        detail: metadataOnly
            ? 'Updating remote mirror metadata.'
            : 'Uploading ${file.relativePath} (${_formatBytes(file.sizeBytes)}).',
        progress: _stepProgress(processedSteps, totalSteps, 0.38, 0.92),
        processedCount: processedSteps,
        totalCount: totalSteps,
        entityCount: workspace.nodeCount,
        fileCount: workspace.fileCount,
      );
      await _uploadMirrorFile(
        accessToken: accessToken,
        remotePath: _remotePath(rootPath, file.relativePath),
        file: file,
        onChunkProgress: (sentBytes, totalBytes) {
          _emitProgress(
            onProgress,
            message: metadataOnly
                ? 'Uploading backup metadata'
                : 'Uploading Dropbox files',
            detail: metadataOnly
                ? 'Updating remote mirror metadata.'
                : 'Uploading ${file.relativePath} (${_formatBytes(sentBytes)} of ${_formatBytes(totalBytes)}).',
            progress: _stepProgress(processedSteps, totalSteps, 0.38, 0.92),
            processedCount: processedSteps,
            totalCount: totalSteps,
            entityCount: workspace.nodeCount,
            fileCount: workspace.fileCount,
          );
        },
      );
      processedSteps += 1;
    }

    _emitProgress(
      onProgress,
      message: 'Writing Dropbox manifest',
      detail: 'Uploading metadata manifest and checksums.',
      progress: 0.94,
      processedCount: processedSteps,
      totalCount: totalSteps,
      entityCount: workspace.nodeCount,
      fileCount: workspace.fileCount,
    );
    await _uploadBytes(
      accessToken: accessToken,
      remotePath: _remotePath(rootPath, VaultMirrorWorkspace.manifestPath),
      bytes: utf8.encode(workspace.manifestText),
    );
    processedSteps += 1;

    // Manifest is committed — now it is safe to remove files it no longer
    // references. (Moved here from before the uploads for crash-consistency.)
    for (final oldPath in staleFiles) {
      _emitProgress(
        onProgress,
        message: 'Cleaning Dropbox mirror',
        detail: 'Deleting stale file $oldPath.',
        progress: _stepProgress(processedSteps, totalSteps, 0.95, 0.97),
        processedCount: processedSteps,
        totalCount: totalSteps,
        entityCount: workspace.nodeCount,
        fileCount: workspace.fileCount,
      );
      await _deletePath(
        accessToken: accessToken,
        remotePath: _remotePath(rootPath, oldPath),
      );
      processedSteps += 1;
    }

    for (final directory in staleDirectories) {
      _emitProgress(
        onProgress,
        message: 'Cleaning Dropbox folders',
        detail: 'Deleting stale folder $directory.',
        progress: 0.97,
        processedCount: processedSteps,
        totalCount: totalSteps,
        entityCount: workspace.nodeCount,
        fileCount: workspace.fileCount,
      );
      await _deletePath(
        accessToken: accessToken,
        remotePath: _remotePath(rootPath, directory),
      );
      processedSteps += 1;
    }

    _emitProgress(
      onProgress,
      message: 'Dropbox mirror complete',
      detail: metadataOnly
          ? 'Updated backup metadata and verified ${_countLabel(directories.length, 'folder')}.'
          : 'Uploaded ${_countLabel(changedFiles.length, 'changed mirror file')} and verified ${_countLabel(directories.length, 'folder')}.',
      progress: 1,
      processedCount: totalSteps,
      totalCount: totalSteps,
      entityCount: workspace.nodeCount,
      fileCount: workspace.fileCount,
    );

    return VaultMirrorResult(
      revision: workspace.revision,
      fileCount: workspace.fileCount,
      directoryCount: workspace.directoryCount,
      entityCount: workspace.nodeCount,
      byteCount: workspace.byteCount,
      checksum: workspace.contentChecksum,
      manifestPath: _remotePath(rootPath, VaultMirrorWorkspace.manifestPath),
      warningMessage: workspace.warningMessage,
    );
  }

  Future<void> _uploadMirrorFile({
    required String accessToken,
    required String remotePath,
    required VaultMirrorFile file,
    void Function(int sentBytes, int totalBytes)? onChunkProgress,
  }) async {
    final sourcePath = file.sourcePath;
    if (sourcePath != null &&
        sourcePath.trim().isNotEmpty &&
        file.sizeBytes > _singleUploadLimitBytes) {
      await _uploadLargeSourceFile(
        accessToken: accessToken,
        remotePath: remotePath,
        sourceFile: File(sourcePath),
        sizeBytes: file.sizeBytes,
        onChunkProgress: onChunkProgress,
      );
      return;
    }

    await _uploadBytes(
      accessToken: accessToken,
      remotePath: remotePath,
      file: file,
    );
  }

  Future<VaultMirrorManifest> _readManifest({
    required String accessToken,
    required String rootPath,
  }) async {
    final bytes = await _downloadBytesOrNull(
      accessToken: accessToken,
      remotePath: _remotePath(rootPath, VaultMirrorWorkspace.manifestPath),
    );
    if (bytes == null) {
      return VaultMirrorManifest.empty();
    }
    try {
      return VaultMirrorManifest.fromJsonText(utf8.decode(bytes));
    } catch (_) {
      return VaultMirrorManifest.empty();
    }
  }

  Future<List<int>?> _downloadBytesOrNull({
    required String accessToken,
    required String remotePath,
  }) async {
    try {
      final response = await dio.post<List<int>>(
        'https://content.dropboxapi.com/2/files/download',
        options: Options(
          responseType: ResponseType.bytes,
          connectTimeout: _connectTimeout,
          sendTimeout: _downloadTimeout,
          receiveTimeout: _downloadTimeout,
          headers: {
            'Authorization': 'Bearer ${accessToken.trim()}',
            'Dropbox-API-Arg': _dropboxApiArg({'path': remotePath}),
          },
        ),
      );
      return response.data;
    } on DioException catch (error) {
      if (error.response?.statusCode == 409) {
        return null;
      }
      rethrow;
    }
  }

  Future<void> _createFolder({
    required String accessToken,
    required String remotePath,
    bool allowExisting = false,
  }) async {
    try {
      await dio.post<void>(
        'https://api.dropboxapi.com/2/files/create_folder_v2',
        data: jsonEncode({'path': remotePath, 'autorename': false}),
        options: Options(
          contentType: 'application/json',
          connectTimeout: _connectTimeout,
          sendTimeout: _metadataTimeout,
          receiveTimeout: _metadataTimeout,
          headers: {'Authorization': 'Bearer ${accessToken.trim()}'},
        ),
      );
    } on DioException catch (error) {
      if (error.response?.statusCode == 409 &&
          allowExisting &&
          _isDropboxConflict(error)) {
        return;
      }
      throw StateError(
        'Dropbox could not create folder $remotePath: ${_dropboxErrorSummary(error)}',
      );
    }
  }

  Future<void> _deletePath({
    required String accessToken,
    required String remotePath,
  }) async {
    try {
      await dio.post<void>(
        'https://api.dropboxapi.com/2/files/delete_v2',
        data: jsonEncode({'path': remotePath}),
        options: Options(
          contentType: 'application/json',
          connectTimeout: _connectTimeout,
          sendTimeout: _metadataTimeout,
          receiveTimeout: _metadataTimeout,
          headers: {'Authorization': 'Bearer ${accessToken.trim()}'},
        ),
      );
    } on DioException catch (error) {
      if (error.response?.statusCode == 409) {
        return;
      }
      rethrow;
    }
  }

  Future<DropboxFileMetadata?> _getMetadataOrNull({
    required String accessToken,
    required String remotePath,
  }) async {
    try {
      final response = await dio.post<Map<String, dynamic>>(
        'https://api.dropboxapi.com/2/files/get_metadata',
        data: jsonEncode({
          'path': remotePath,
          'include_media_info': false,
          'include_deleted': false,
          'include_has_explicit_shared_members': false,
        }),
        options: Options(
          contentType: 'application/json',
          connectTimeout: _connectTimeout,
          sendTimeout: _metadataTimeout,
          receiveTimeout: _metadataTimeout,
          headers: {'Authorization': 'Bearer ${accessToken.trim()}'},
        ),
      );
      final data = response.data;
      if (data == null || data['.tag'] == 'folder') {
        return null;
      }
      return DropboxFileMetadata(
        pathLower: '${data['path_lower'] ?? ''}'.trim(),
        rev: '${data['rev'] ?? ''}'.trim(),
        contentHash: '${data['content_hash'] ?? ''}'.trim(),
      );
    } on DioException catch (error) {
      if (error.response?.statusCode == 409) {
        return null;
      }
      rethrow;
    }
  }

  Future<List<String>> _listFilesRecursive({
    required String accessToken,
    required String remotePath,
  }) async {
    final files = <String>[];
    String? cursor;
    var hasMore = true;
    while (hasMore) {
      try {
        final response = cursor == null
            ? await dio.post<Map<String, dynamic>>(
                'https://api.dropboxapi.com/2/files/list_folder',
                data: jsonEncode({
                  'path': remotePath,
                  'recursive': true,
                  'include_media_info': false,
                  'include_deleted': false,
                  'include_has_explicit_shared_members': false,
                }),
                options: Options(
                  contentType: 'application/json',
                  connectTimeout: _connectTimeout,
                  sendTimeout: _metadataTimeout,
                  receiveTimeout: _metadataTimeout,
                  headers: {'Authorization': 'Bearer ${accessToken.trim()}'},
                ),
              )
            : await dio.post<Map<String, dynamic>>(
                'https://api.dropboxapi.com/2/files/list_folder/continue',
                data: jsonEncode({'cursor': cursor}),
                options: Options(
                  contentType: 'application/json',
                  connectTimeout: _connectTimeout,
                  sendTimeout: _metadataTimeout,
                  receiveTimeout: _metadataTimeout,
                  headers: {'Authorization': 'Bearer ${accessToken.trim()}'},
                ),
              );
        final data = response.data ?? const <String, dynamic>{};
        final entries = data['entries'];
        if (entries is List) {
          for (final entry in entries.whereType<Map>()) {
            if (entry['.tag'] == 'file') {
              final path =
                  '${entry['path_display'] ?? entry['path_lower'] ?? ''}'
                      .trim();
              if (path.isNotEmpty) {
                files.add(path);
              }
            }
          }
        }
        cursor = '${data['cursor'] ?? ''}'.trim();
        hasMore = data['has_more'] == true && cursor.isNotEmpty;
      } on DioException catch (error) {
        if (error.response?.statusCode == 409) {
          return const <String>[];
        }
        rethrow;
      }
    }
    return files;
  }

  Future<void> _ensureSyncFolders({
    required String accessToken,
    required String rootPath,
    Set<String> deviceIds = const <String>{},
  }) async {
    for (final path in [
      VaultMirrorWorkspace.metadataDir,
      _syncRootPath,
      '$_syncRootPath/ops',
      '$_syncRootPath/op_batches',
      '$_syncRootPath/checkpoints',
      for (final deviceId in deviceIds)
        '$_syncRootPath/ops/${_safePathSegment(deviceId)}',
      for (final deviceId in deviceIds)
        '$_syncRootPath/op_batches/${_safePathSegment(deviceId)}',
    ]) {
      await _createFolder(
        accessToken: accessToken,
        remotePath: _remotePath(rootPath, path),
        allowExisting: true,
      );
    }
  }

  Future<Map<String, dynamic>?> _uploadBytes({
    required String accessToken,
    required String remotePath,
    List<int>? bytes,
    VaultMirrorFile? file,
    Object? mode = 'overwrite',
    bool strictConflict = false,
  }) async {
    final body = file == null
        ? bytes ?? const <int>[]
        : file.isInline
        ? await file.readBytes()
        : file.openRead();
    final contentLength = file?.sizeBytes ?? (bytes?.length ?? 0);
    try {
      final response = await dio.post<Map<String, dynamic>>(
        'https://content.dropboxapi.com/2/files/upload',
        data: body,
        options: Options(
          contentType: 'application/octet-stream',
          connectTimeout: _connectTimeout,
          sendTimeout: _uploadTimeout,
          receiveTimeout: _uploadTimeout,
          headers: {
            'Authorization': 'Bearer ${accessToken.trim()}',
            'Content-Length': '$contentLength',
            'Dropbox-API-Arg': _dropboxApiArg({
              'path': remotePath,
              'mode': mode,
              'autorename': false,
              'mute': true,
              'strict_conflict': strictConflict,
            }),
          },
        ),
      );
      return response.data;
    } on DioException catch (error) {
      throw StateError(
        'Dropbox could not upload $remotePath: ${_dropboxErrorSummary(error)}',
      );
    }
  }

  Future<void> _uploadLargeSourceFile({
    required String accessToken,
    required String remotePath,
    required File sourceFile,
    required int sizeBytes,
    void Function(int sentBytes, int totalBytes)? onChunkProgress,
  }) async {
    final raf = await sourceFile.open();
    try {
      var offset = 0;
      final firstChunk = await raf.read(
        math.min(_chunkSizeBytes, sizeBytes - offset),
      );
      final sessionId = await _startUploadSession(
        accessToken: accessToken,
        chunk: firstChunk,
      );
      offset += firstChunk.length;
      onChunkProgress?.call(offset, sizeBytes);

      while (offset < sizeBytes) {
        final chunk = await raf.read(
          math.min(_chunkSizeBytes, sizeBytes - offset),
        );
        if (offset + chunk.length >= sizeBytes) {
          await _finishUploadSession(
            accessToken: accessToken,
            sessionId: sessionId,
            offset: offset,
            remotePath: remotePath,
            chunk: chunk,
          );
          offset += chunk.length;
          onChunkProgress?.call(offset, sizeBytes);
        } else {
          await _appendUploadSession(
            accessToken: accessToken,
            sessionId: sessionId,
            offset: offset,
            chunk: chunk,
          );
          offset += chunk.length;
          onChunkProgress?.call(offset, sizeBytes);
        }
      }
    } finally {
      await raf.close();
    }
  }

  Future<String> _startUploadSession({
    required String accessToken,
    required List<int> chunk,
  }) async {
    late final Response<Map<String, dynamic>> response;
    try {
      response = await dio.post<Map<String, dynamic>>(
        'https://content.dropboxapi.com/2/files/upload_session/start',
        data: chunk,
        options: Options(
          contentType: 'application/octet-stream',
          connectTimeout: _connectTimeout,
          sendTimeout: _uploadTimeout,
          receiveTimeout: _uploadTimeout,
          headers: {
            'Authorization': 'Bearer ${accessToken.trim()}',
            'Content-Length': '${chunk.length}',
            'Dropbox-API-Arg': _dropboxApiArg({'close': false}),
          },
        ),
      );
    } on DioException catch (error) {
      throw StateError(
        'Dropbox could not start upload session: ${_dropboxErrorSummary(error)}',
      );
    }
    final sessionId = response.data?['session_id'] as String?;
    if (sessionId == null || sessionId.isEmpty) {
      throw StateError('Dropbox did not return an upload session id.');
    }
    return sessionId;
  }

  Future<String> _hashBytes(List<int> bytes) async {
    final hash = await Sha256().hash(bytes);
    return hash.bytes.map((it) => it.toRadixString(16).padLeft(2, '0')).join();
  }

  Future<void> _appendUploadSession({
    required String accessToken,
    required String sessionId,
    required int offset,
    required List<int> chunk,
  }) async {
    try {
      await dio.post<void>(
        'https://content.dropboxapi.com/2/files/upload_session/append_v2',
        data: chunk,
        options: Options(
          contentType: 'application/octet-stream',
          connectTimeout: _connectTimeout,
          sendTimeout: _uploadTimeout,
          receiveTimeout: _uploadTimeout,
          headers: {
            'Authorization': 'Bearer ${accessToken.trim()}',
            'Content-Length': '${chunk.length}',
            'Dropbox-API-Arg': _dropboxApiArg({
              'cursor': {'session_id': sessionId, 'offset': offset},
              'close': false,
            }),
          },
        ),
      );
    } on DioException catch (error) {
      throw StateError(
        'Dropbox could not append upload chunk: ${_dropboxErrorSummary(error)}',
      );
    }
  }

  Future<void> _finishUploadSession({
    required String accessToken,
    required String sessionId,
    required int offset,
    required String remotePath,
    required List<int> chunk,
  }) async {
    try {
      await dio.post<void>(
        'https://content.dropboxapi.com/2/files/upload_session/finish',
        data: chunk,
        options: Options(
          contentType: 'application/octet-stream',
          connectTimeout: _connectTimeout,
          sendTimeout: _uploadTimeout,
          receiveTimeout: _uploadTimeout,
          headers: {
            'Authorization': 'Bearer ${accessToken.trim()}',
            'Content-Length': '${chunk.length}',
            'Dropbox-API-Arg': _dropboxApiArg({
              'cursor': {'session_id': sessionId, 'offset': offset},
              'commit': {
                'path': remotePath,
                'mode': 'overwrite',
                'autorename': false,
                'mute': true,
                'strict_conflict': false,
              },
            }),
          },
        ),
      );
    } on DioException catch (error) {
      throw StateError(
        'Dropbox could not finish upload $remotePath: ${_dropboxErrorSummary(error)}',
      );
    }
  }

  String _normalizeRoot(String directoryPath) {
    final trimmed = directoryPath.trim().isEmpty
        ? '/Credence'
        : directoryPath.trim();
    return trimmed.startsWith('/') ? trimmed : '/$trimmed';
  }

  String _remotePath(String rootPath, String relativePath) {
    final clean = relativePath
        .trim()
        .replaceAll('\\', '/')
        .split('/')
        .where((part) => part.isNotEmpty && part != '.' && part != '..')
        .join('/');
    if (clean.isEmpty) {
      return rootPath;
    }
    return '$rootPath/$clean';
  }

  String _safePathSegment(String value) {
    final sanitized = value
        .trim()
        .replaceAll(RegExp(r'[^A-Za-z0-9._-]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
    return sanitized.isEmpty ? 'unknown' : sanitized;
  }

  String _operationIdFromFilePath(String path) {
    final fileName = path.replaceAll('\\', '/').split('/').last;
    final clean = fileName.endsWith('.json')
        ? fileName.substring(0, fileName.length - '.json'.length)
        : fileName;
    final separator = clean.indexOf('_');
    if (separator < 0 || separator + 1 >= clean.length) {
      return clean;
    }
    return clean.substring(separator + 1);
  }

  double _stepProgress(
    int processedSteps,
    int totalSteps,
    double start,
    double end,
  ) {
    if (totalSteps <= 0) {
      return end;
    }
    final fraction = processedSteps / totalSteps;
    return start + ((end - start) * fraction.clamp(0, 1));
  }

  void _emitProgress(
    VaultSyncProgressCallback? onProgress, {
    required String message,
    required String detail,
    required double progress,
    int? processedCount,
    int? totalCount,
    int? entityCount,
    int? fileCount,
  }) {
    final boundedProgress = progress.clamp(0, 1).toDouble();
    developer.log(
      '[DropboxMirror] $message - $detail '
      '(${(boundedProgress * 100).toStringAsFixed(0)}%)',
      name: 'DropboxMirror',
    );
    onProgress?.call(
      VaultSyncProgressEntity(
        message: message,
        detail: detail,
        progress: boundedProgress,
        processedCount: processedCount,
        totalCount: totalCount,
        entityCount: entityCount,
        fileCount: fileCount,
      ),
    );
  }

  String _dropboxApiArg(Map<String, dynamic> value) {
    return _escapeHeaderJson(jsonEncode(value));
  }

  String _escapeHeaderJson(String source) {
    final buffer = StringBuffer();
    for (final rune in source.runes) {
      if (rune < 0x20 || rune > 0x7e) {
        if (rune <= 0xffff) {
          buffer.write('\\u${rune.toRadixString(16).padLeft(4, '0')}');
        } else {
          final value = rune - 0x10000;
          final high = 0xd800 + (value >> 10);
          final low = 0xdc00 + (value & 0x3ff);
          buffer
            ..write('\\u${high.toRadixString(16).padLeft(4, '0')}')
            ..write('\\u${low.toRadixString(16).padLeft(4, '0')}');
        }
      } else {
        buffer.writeCharCode(rune);
      }
    }
    return buffer.toString();
  }

  bool _isDropboxConflict(DioException error) {
    if (error.response?.statusCode != 409) {
      return false;
    }
    final body = _dropboxErrorBody(error).toLowerCase();
    return body.contains('conflict') &&
        !body.contains('not_found') &&
        !body.contains('not_folder');
  }

  String _dropboxErrorSummary(DioException error) {
    final status = error.response?.statusCode;
    final body = _dropboxErrorBody(error);
    if (body.isNotEmpty) {
      return status == null ? body : 'HTTP $status $body';
    }
    return status == null ? error.message ?? '$error' : 'HTTP $status';
  }

  String _dropboxErrorBody(DioException error) {
    final data = error.response?.data;
    if (data == null) {
      return '';
    }
    if (data is List<int>) {
      return utf8.decode(data, allowMalformed: true).trim();
    }
    if (data is String) {
      return data.trim();
    }
    return '$data'.trim();
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    }
    final kb = bytes / 1024;
    if (kb < 1024) {
      return '${kb.toStringAsFixed(kb < 10 ? 1 : 0)} KB';
    }
    final mb = kb / 1024;
    if (mb < 1024) {
      return '${mb.toStringAsFixed(mb < 10 ? 1 : 0)} MB';
    }
    final gb = mb / 1024;
    return '${gb.toStringAsFixed(gb < 10 ? 1 : 0)} GB';
  }

  String _countLabel(int count, String singular, [String? plural]) {
    return '$count ${count == 1 ? singular : plural ?? '${singular}s'}';
  }

  bool _isMirrorMetadataFile(String path) {
    return path == VaultMirrorWorkspace.snapshotPath;
  }

  Set<String> _requiredDirectoriesForFiles(List<VaultMirrorFile> files) {
    final directories = <String>{};
    for (final file in files) {
      directories.addAll(_parentDirectories(file.relativePath));
    }
    return directories;
  }

  Set<String> _parentDirectories(String relativePath) {
    final normalized = relativePath.replaceAll('\\', '/').trim();
    final segments = normalized
        .split('/')
        .where((segment) => segment.trim().isNotEmpty)
        .toList(growable: false);
    final directories = <String>{};
    for (var i = 1; i < segments.length; i++) {
      directories.add(segments.take(i).join('/'));
    }
    return directories;
  }
}
