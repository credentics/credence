import 'dart:convert';
import 'dart:developer' as developer;

import 'package:cryptography/cryptography.dart';
import 'package:dio/dio.dart';
import 'package:pass_doc_manager/data/vault_sync/mirror/vault_mirror_workspace.dart';
import 'package:pass_doc_manager/domain/vault_sync/entities/vault_sync_head_entity.dart';
import 'package:pass_doc_manager/domain/vault_sync/entities/vault_sync_progress_entity.dart';

class GoogleDriveMirrorDataSource {
  const GoogleDriveMirrorDataSource({required this.dio});

  final Dio dio;

  static const String _driveApiBase = 'https://www.googleapis.com/drive/v3';
  static const String _uploadApiBase =
      'https://www.googleapis.com/upload/drive/v3';

  bool get supportsPassiveCheck => true;

  int get estimatedPassiveCheckCost => 4096;

  Future<VaultSyncHeadEntity?> readHead({
    required String accessToken,
    required String directoryPath,
  }) async {
    final stopwatch = Stopwatch()..start();
    var bytesRead = 0;
    final rootId = await _findFolderIdByPath(
      accessToken: accessToken,
      rootId: 'root',
      relativePath: directoryPath,
    );
    if (rootId == null) {
      stopwatch.stop();
      developer.log(
        '[GoogleDrivePassiveCheck] Mirror root not found '
        'in ${stopwatch.elapsedMilliseconds}ms',
        name: 'GoogleDriveMirror',
      );
      return null;
    }
    final headId = await _findFileIdByPath(
      accessToken: accessToken,
      rootId: rootId,
      relativePath: VaultMirrorWorkspace.headPath,
    );
    if (headId != null) {
      final bytes = await _downloadFileBytes(
        accessToken: accessToken,
        fileId: headId,
      );
      bytesRead += bytes.length;
      stopwatch.stop();
      developer.log(
        '[GoogleDrivePassiveCheck] Read head.json ($bytesRead bytes) '
        'in ${stopwatch.elapsedMilliseconds}ms',
        name: 'GoogleDriveMirror',
      );
      return VaultSyncHeadEntity.fromJsonText(utf8.decode(bytes));
    }

    final fallbackId = await _findFileIdByPath(
      accessToken: accessToken,
      rootId: rootId,
      relativePath: VaultMirrorWorkspace.manifestPath,
    );
    if (fallbackId == null) {
      stopwatch.stop();
      developer.log(
        '[GoogleDrivePassiveCheck] No head.json or manifest.json found '
        'in ${stopwatch.elapsedMilliseconds}ms',
        name: 'GoogleDriveMirror',
      );
      return null;
    }
    final fallback = await _downloadFileBytes(
      accessToken: accessToken,
      fileId: fallbackId,
    );
    bytesRead += fallback.length;
    stopwatch.stop();
    developer.log(
      '[GoogleDrivePassiveCheck] head.json missing; read manifest fallback '
      '($bytesRead bytes) in ${stopwatch.elapsedMilliseconds}ms',
      name: 'GoogleDriveMirror',
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
      provider: 'google_drive',
      fileCount: manifest.filesByPath.length,
      directoryCount: manifest.managedDirectories.length,
    );
  }

  Future<VaultSyncHeadEntity?> readManifestHeadFallback({
    required String accessToken,
    required String directoryPath,
  }) async {
    final rootId = await _findFolderIdByPath(
      accessToken: accessToken,
      rootId: 'root',
      relativePath: directoryPath,
    );
    if (rootId == null) {
      return null;
    }
    final fileId = await _findFileIdByPath(
      accessToken: accessToken,
      rootId: rootId,
      relativePath: VaultMirrorWorkspace.manifestPath,
    );
    if (fileId == null) {
      return null;
    }
    final bytes = await _downloadFileBytes(
      accessToken: accessToken,
      fileId: fileId,
    );
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
      provider: 'google_drive',
      fileCount: manifest.filesByPath.length,
      directoryCount: manifest.managedDirectories.length,
    );
  }

  Future<void> writeHead({
    required String accessToken,
    required String directoryPath,
    required VaultSyncHeadEntity head,
  }) async {
    final rootId = await _getOrCreateFolderPath(
      accessToken: accessToken,
      path: directoryPath,
    );
    final headFolderId = await _getOrCreateFolderPath(
      accessToken: accessToken,
      path: _parentPath(VaultMirrorWorkspace.headPath),
      rootFolderId: rootId,
    );
    await _uploadBytes(
      accessToken: accessToken,
      parentFolderId: headFolderId,
      fileName: _fileName(VaultMirrorWorkspace.headPath),
      bytes: utf8.encode(head.toJsonText()),
    );
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
    _emitProgress(
      onProgress,
      message: 'Connecting to Google Drive',
      detail: 'Ensuring the mirror root exists.',
      progress: 0.12,
      totalCount: workspace.fileCount + workspace.directoryCount + 1,
      entityCount: workspace.nodeCount,
      fileCount: workspace.fileCount,
    );
    final rootId = await _getOrCreateFolderPath(
      accessToken: accessToken,
      path: directoryPath,
    );
    final previous = await _readManifest(
      accessToken: accessToken,
      rootId: rootId,
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
      message: 'Planning Google Drive mirror',
      detail: metadataOnly
          ? 'Backup metadata needs an update. ${_countLabel(requiredDirectories.length, 'folder')} needed.'
          : '${_countLabel(changedFiles.length, 'changed mirror file')}, ${_countLabel(requiredDirectories.length, 'folder')} needed, ${_countLabel(staleFiles.length, 'stale file')} to remove.',
      progress: 0.16,
      processedCount: processedSteps,
      totalCount: totalSteps,
      entityCount: workspace.nodeCount,
      fileCount: workspace.fileCount,
    );

    for (final oldPath in staleFiles) {
      _emitProgress(
        onProgress,
        message: 'Cleaning Google Drive mirror',
        detail: 'Deleting stale file $oldPath.',
        progress: _stepProgress(processedSteps, totalSteps, 0.16, 0.24),
        processedCount: processedSteps,
        totalCount: totalSteps,
        entityCount: workspace.nodeCount,
        fileCount: workspace.fileCount,
      );
      await _deleteFileByPath(
        accessToken: accessToken,
        rootId: rootId,
        relativePath: oldPath,
      );
      processedSteps += 1;
    }

    final directories = requiredDirectories.toList(growable: false)
      ..sort((a, b) => a.length.compareTo(b.length));
    final folderIdsByPath = <String, String>{'': rootId};
    for (final directory in directories) {
      _emitProgress(
        onProgress,
        message: 'Creating Google Drive folders',
        detail: 'Ensuring $directory exists.',
        progress: _stepProgress(processedSteps, totalSteps, 0.24, 0.38),
        processedCount: processedSteps,
        totalCount: totalSteps,
        entityCount: workspace.nodeCount,
        fileCount: workspace.fileCount,
      );
      folderIdsByPath[directory] = await _getOrCreateFolderPath(
        accessToken: accessToken,
        path: directory,
        rootFolderId: rootId,
      );
      processedSteps += 1;
    }

    for (final file in changedFiles) {
      _emitProgress(
        onProgress,
        message: metadataOnly
            ? 'Uploading backup metadata'
            : 'Uploading Google Drive files',
        detail: metadataOnly
            ? 'Updating remote mirror metadata.'
            : 'Uploading ${file.relativePath} (${_formatBytes(file.sizeBytes)}).',
        progress: _stepProgress(processedSteps, totalSteps, 0.38, 0.92),
        processedCount: processedSteps,
        totalCount: totalSteps,
        entityCount: workspace.nodeCount,
        fileCount: workspace.fileCount,
      );
      final directory = _parentPath(file.relativePath);
      final parentId =
          folderIdsByPath[directory] ??
          await _getOrCreateFolderPath(
            accessToken: accessToken,
            path: directory,
            rootFolderId: rootId,
          );
      await _uploadMirrorFile(
        accessToken: accessToken,
        parentFolderId: parentId,
        fileName: _fileName(file.relativePath),
        file: file,
      );
      processedSteps += 1;
    }

    _emitProgress(
      onProgress,
      message: 'Writing Google Drive manifest',
      detail: 'Uploading metadata manifest and checksums.',
      progress: 0.94,
      processedCount: processedSteps,
      totalCount: totalSteps,
      entityCount: workspace.nodeCount,
      fileCount: workspace.fileCount,
    );
    final manifestFolderId =
        folderIdsByPath[_parentPath(VaultMirrorWorkspace.manifestPath)] ??
        await _getOrCreateFolderPath(
          accessToken: accessToken,
          path: _parentPath(VaultMirrorWorkspace.manifestPath),
          rootFolderId: rootId,
        );
    await _uploadBytes(
      accessToken: accessToken,
      parentFolderId: manifestFolderId,
      fileName: _fileName(VaultMirrorWorkspace.manifestPath),
      bytes: utf8.encode(workspace.manifestText),
    );
    processedSteps += 1;

    for (final directory in staleDirectories) {
      _emitProgress(
        onProgress,
        message: 'Cleaning Google Drive folders',
        detail: 'Deleting stale folder $directory.',
        progress: 0.97,
        processedCount: processedSteps,
        totalCount: totalSteps,
        entityCount: workspace.nodeCount,
        fileCount: workspace.fileCount,
      );
      await _deleteEmptyFolderByPath(
        accessToken: accessToken,
        rootId: rootId,
        relativePath: directory,
      );
      processedSteps += 1;
    }

    _emitProgress(
      onProgress,
      message: 'Google Drive mirror complete',
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
      manifestPath:
          '${_normalizeRootLabel(directoryPath)}/'
          '${VaultMirrorWorkspace.manifestPath}',
      warningMessage: workspace.warningMessage,
    );
  }

  Future<void> _uploadMirrorFile({
    required String accessToken,
    required String parentFolderId,
    required String fileName,
    required VaultMirrorFile file,
  }) async {
    if (file.isInline) {
      await _uploadBytes(
        accessToken: accessToken,
        parentFolderId: parentFolderId,
        fileName: fileName,
        bytes: await file.readBytes(),
      );
      return;
    }
    await _uploadStream(
      accessToken: accessToken,
      parentFolderId: parentFolderId,
      fileName: fileName,
      stream: file.openRead(),
      sizeBytes: file.sizeBytes,
    );
  }

  Future<void> _uploadBytes({
    required String accessToken,
    required String parentFolderId,
    required String fileName,
    required List<int> bytes,
  }) {
    return _uploadStream(
      accessToken: accessToken,
      parentFolderId: parentFolderId,
      fileName: fileName,
      stream: Stream<List<int>>.value(bytes),
      sizeBytes: bytes.length,
    );
  }

  Future<void> _uploadStream({
    required String accessToken,
    required String parentFolderId,
    required String fileName,
    required Stream<List<int>> stream,
    required int sizeBytes,
  }) async {
    final fileId =
        await _findFileIdByName(
          accessToken: accessToken,
          name: fileName,
          parentFolderId: parentFolderId,
        ) ??
        await _createFileMetadata(
          accessToken: accessToken,
          name: fileName,
          parentFolderId: parentFolderId,
        );
    try {
      await dio.patch<void>(
        '$_uploadApiBase/files/$fileId?uploadType=media',
        data: stream,
        options: Options(
          contentType: 'application/octet-stream',
          headers: {
            ..._authHeader(accessToken),
            'Content-Length': '$sizeBytes',
          },
        ),
      );
    } on DioException catch (error) {
      throw StateError(
        'Google Drive could not upload $fileName: ${_driveErrorSummary(error)}',
      );
    }
  }

  Future<VaultMirrorManifest> _readManifest({
    required String accessToken,
    required String rootId,
  }) async {
    final fileId = await _findFileIdByPath(
      accessToken: accessToken,
      rootId: rootId,
      relativePath: VaultMirrorWorkspace.manifestPath,
    );
    if (fileId == null) {
      return VaultMirrorManifest.empty();
    }
    try {
      final response = await dio.get<List<int>>(
        '$_driveApiBase/files/$fileId',
        queryParameters: {'alt': 'media'},
        options: Options(
          responseType: ResponseType.bytes,
          headers: _authHeader(accessToken),
        ),
      );
      final bytes = response.data;
      if (bytes == null) {
        return VaultMirrorManifest.empty();
      }
      return VaultMirrorManifest.fromJsonText(utf8.decode(bytes));
    } catch (_) {
      return VaultMirrorManifest.empty();
    }
  }

  Future<List<int>> _downloadFileBytes({
    required String accessToken,
    required String fileId,
  }) async {
    final response = await dio.get<List<int>>(
      '$_driveApiBase/files/$fileId',
      queryParameters: {'alt': 'media'},
      options: Options(
        responseType: ResponseType.bytes,
        headers: _authHeader(accessToken),
      ),
    );
    return response.data ?? const <int>[];
  }

  Future<String> _getOrCreateFolderPath({
    required String accessToken,
    required String path,
    String rootFolderId = 'root',
  }) async {
    var parentId = rootFolderId;
    for (final segment in _pathSegments(
      path,
      defaultRoot: rootFolderId == 'root',
    )) {
      parentId = await _findOrCreateFolder(
        accessToken: accessToken,
        name: segment,
        parentFolderId: parentId,
      );
    }
    return parentId;
  }

  Future<String> _findOrCreateFolder({
    required String accessToken,
    required String name,
    required String parentFolderId,
  }) async {
    final existing = await _findFolderIdByName(
      accessToken: accessToken,
      name: name,
      parentFolderId: parentFolderId,
    );
    if (existing != null) {
      return existing;
    }
    final response = await dio.post<Map<String, dynamic>>(
      '$_driveApiBase/files',
      data: jsonEncode({
        'name': name,
        'mimeType': 'application/vnd.google-apps.folder',
        'parents': [parentFolderId],
      }),
      options: Options(
        contentType: 'application/json',
        headers: _authHeader(accessToken),
      ),
    );
    final id = response.data?['id'] as String?;
    if (id == null || id.isEmpty) {
      throw StateError('Google Drive did not return a folder id for $name.');
    }
    return id;
  }

  Future<String?> _findFolderIdByName({
    required String accessToken,
    required String name,
    required String parentFolderId,
  }) {
    return _findChildIdByName(
      accessToken: accessToken,
      name: name,
      parentFolderId: parentFolderId,
      foldersOnly: true,
    );
  }

  Future<String?> _findFileIdByName({
    required String accessToken,
    required String name,
    required String parentFolderId,
  }) {
    return _findChildIdByName(
      accessToken: accessToken,
      name: name,
      parentFolderId: parentFolderId,
      foldersOnly: false,
    );
  }

  Future<String?> _findChildIdByName({
    required String accessToken,
    required String name,
    required String parentFolderId,
    required bool foldersOnly,
  }) async {
    final mimeClause = foldersOnly
        ? "and mimeType='application/vnd.google-apps.folder'"
        : "and mimeType!='application/vnd.google-apps.folder'";
    final response = await dio.get<Map<String, dynamic>>(
      '$_driveApiBase/files',
      queryParameters: {
        'q':
            "name='${_escapeDriveQueryValue(name)}' "
            "and '$parentFolderId' in parents "
            '$mimeClause and trashed=false',
        'fields': 'files(id)',
        'pageSize': 1,
      },
      options: Options(headers: _authHeader(accessToken)),
    );
    final files = (response.data?['files'] as List<dynamic>?) ?? [];
    if (files.isEmpty) {
      return null;
    }
    return (files.first as Map<String, dynamic>)['id'] as String?;
  }

  Future<String> _createFileMetadata({
    required String accessToken,
    required String name,
    required String parentFolderId,
  }) async {
    final response = await dio.post<Map<String, dynamic>>(
      '$_driveApiBase/files',
      data: jsonEncode({
        'name': name,
        'parents': [parentFolderId],
      }),
      options: Options(
        contentType: 'application/json',
        headers: _authHeader(accessToken),
      ),
    );
    final id = response.data?['id'] as String?;
    if (id == null || id.isEmpty) {
      throw StateError('Google Drive did not return a file id for $name.');
    }
    return id;
  }

  Future<String?> _findFileIdByPath({
    required String accessToken,
    required String rootId,
    required String relativePath,
  }) async {
    final parentPath = _parentPath(relativePath);
    final parentId = await _findFolderIdByPath(
      accessToken: accessToken,
      rootId: rootId,
      relativePath: parentPath,
    );
    if (parentId == null) {
      return null;
    }
    return _findFileIdByName(
      accessToken: accessToken,
      name: _fileName(relativePath),
      parentFolderId: parentId,
    );
  }

  Future<String?> _findFolderIdByPath({
    required String accessToken,
    required String rootId,
    required String relativePath,
  }) async {
    var parentId = rootId;
    for (final segment in _pathSegments(relativePath)) {
      final next = await _findFolderIdByName(
        accessToken: accessToken,
        name: segment,
        parentFolderId: parentId,
      );
      if (next == null) {
        return null;
      }
      parentId = next;
    }
    return parentId;
  }

  Future<void> _deleteFileByPath({
    required String accessToken,
    required String rootId,
    required String relativePath,
  }) async {
    final fileId = await _findFileIdByPath(
      accessToken: accessToken,
      rootId: rootId,
      relativePath: relativePath,
    );
    if (fileId == null) {
      return;
    }
    await _deleteById(accessToken: accessToken, id: fileId);
  }

  Future<void> _deleteEmptyFolderByPath({
    required String accessToken,
    required String rootId,
    required String relativePath,
  }) async {
    final folderId = await _findFolderIdByPath(
      accessToken: accessToken,
      rootId: rootId,
      relativePath: relativePath,
    );
    if (folderId == null || await _hasChildren(accessToken, folderId)) {
      return;
    }
    await _deleteById(accessToken: accessToken, id: folderId);
  }

  Future<void> _deleteById({
    required String accessToken,
    required String id,
  }) async {
    try {
      await dio.delete<void>(
        '$_driveApiBase/files/$id',
        options: Options(headers: _authHeader(accessToken)),
      );
    } on DioException catch (error) {
      if (error.response?.statusCode == 404) {
        return;
      }
      rethrow;
    }
  }

  Future<bool> _hasChildren(String accessToken, String folderId) async {
    final response = await dio.get<Map<String, dynamic>>(
      '$_driveApiBase/files',
      queryParameters: {
        'q': "'$folderId' in parents and trashed=false",
        'fields': 'files(id)',
        'pageSize': 1,
      },
      options: Options(headers: _authHeader(accessToken)),
    );
    final files = (response.data?['files'] as List<dynamic>?) ?? [];
    return files.isNotEmpty;
  }

  Map<String, String> _authHeader(String accessToken) => {
    'Authorization': 'Bearer ${accessToken.trim()}',
  };

  List<String> _pathSegments(String path, {bool defaultRoot = false}) {
    final cleaned = path
        .trim()
        .replaceAll('\\', '/')
        .split('/')
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty && part != '.' && part != '..')
        .toList(growable: false);
    if (cleaned.isEmpty && defaultRoot) {
      return const ['Credence'];
    }
    return cleaned;
  }

  String _parentPath(String relativePath) {
    final parts = _pathSegments(relativePath);
    if (parts.length <= 1) {
      return '';
    }
    return parts.take(parts.length - 1).join('/');
  }

  String _fileName(String relativePath) {
    final parts = _pathSegments(relativePath);
    if (parts.isEmpty) {
      throw StateError('Invalid Google Drive file path: $relativePath');
    }
    return parts.last;
  }

  Set<String> _requiredDirectoriesForFiles(List<VaultMirrorFile> files) {
    final directories = <String>{};
    for (final file in files) {
      directories.addAll(_parentDirectories(file.relativePath));
    }
    return directories;
  }

  Set<String> _parentDirectories(String relativePath) {
    final parts = _pathSegments(relativePath);
    final directories = <String>{};
    for (var i = 1; i < parts.length; i++) {
      directories.add(parts.take(i).join('/'));
    }
    return directories;
  }

  String _normalizeRootLabel(String directoryPath) {
    final parts = _pathSegments(directoryPath, defaultRoot: true);
    return '/${parts.join('/')}';
  }

  String _escapeDriveQueryValue(String value) {
    return value.replaceAll('\\', '\\\\').replaceAll("'", r"\'");
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
      '[GoogleDriveMirror] $message - $detail '
      '(${(boundedProgress * 100).toStringAsFixed(0)}%)',
      name: 'GoogleDriveMirror',
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

  String _driveErrorSummary(DioException error) {
    final status = error.response?.statusCode;
    final data = error.response?.data;
    final body = data is List<int>
        ? utf8.decode(data, allowMalformed: true).trim()
        : '${data ?? error.message ?? error}'.trim();
    return status == null ? body : 'HTTP $status $body';
  }

  Future<String> _hashBytes(List<int> bytes) async {
    final hash = await Sha256().hash(bytes);
    return hash.bytes.map((it) => it.toRadixString(16).padLeft(2, '0')).join();
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
}
