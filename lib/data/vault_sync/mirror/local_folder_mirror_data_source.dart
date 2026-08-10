import 'dart:io';
import 'dart:convert';

import 'package:cryptography/cryptography.dart';
import 'package:pass_doc_manager/data/vault_sync/mirror/vault_mirror_workspace.dart';
import 'package:pass_doc_manager/domain/vault_sync/entities/vault_sync_head_entity.dart';
import 'package:pass_doc_manager/domain/vault_sync/entities/vault_sync_progress_entity.dart';

class LocalFolderMirrorDataSource {
  const LocalFolderMirrorDataSource();

  bool get supportsPassiveCheck => true;

  int get estimatedPassiveCheckCost => 2048;

  Future<VaultSyncHeadEntity?> readHead({required String folderPath}) async {
    final root = Directory(folderPath.trim());
    if (!root.existsSync()) {
      return null;
    }

    final headFile = File(_resolve(root, VaultMirrorWorkspace.headPath));
    if (headFile.existsSync()) {
      final text = await headFile.readAsString();
      return VaultSyncHeadEntity.fromJsonText(text);
    }

    return readManifestHeadFallback(folderPath: folderPath);
  }

  Future<VaultSyncHeadEntity?> readManifestHeadFallback({
    required String folderPath,
  }) async {
    final root = Directory(folderPath.trim());
    final manifestFile = File(
      _resolve(root, VaultMirrorWorkspace.manifestPath),
    );
    if (!manifestFile.existsSync()) {
      return null;
    }
    final text = await manifestFile.readAsString();
    final manifest = VaultMirrorManifest.fromJsonText(text);
    if (manifest.revision <= 0) {
      return null;
    }
    return VaultSyncHeadEntity(
      revision: manifest.revision,
      deviceId: manifest.deviceId,
      manifestHash: manifest.contentChecksum.isNotEmpty
          ? manifest.contentChecksum
          : await _hashText(text),
      generatedAtIso: manifest.generatedAtIso,
      provider: 'local',
      fileCount: manifest.filesByPath.length,
      directoryCount: manifest.managedDirectories.length,
    );
  }

  Future<void> writeHead({
    required String folderPath,
    required VaultSyncHeadEntity head,
  }) async {
    final root = Directory(folderPath.trim());
    if (!root.existsSync()) {
      await root.create(recursive: true);
    }
    final file = File(_resolve(root, VaultMirrorWorkspace.headPath));
    await file.parent.create(recursive: true);
    await file.writeAsString(head.toJsonText(), flush: true);
  }

  Future<VaultMirrorResult> writeWorkspace({
    required String folderPath,
    required VaultMirrorWorkspace workspace,
    bool metadataOnly = false,
    Set<String>? allowedChangedFilePaths,
    Set<String>? allowedDeletedFilePaths,
    VaultSyncProgressCallback? onProgress,
  }) async {
    final root = Directory(folderPath.trim());
    if (!root.existsSync()) {
      await root.create(recursive: true);
    }

    final previous = await _readManifest(root);
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
        .where((file) {
          final output = File(_resolve(root, file.relativePath));
          return previous.fileHashesByPath[file.relativePath] !=
                  file.contentHash ||
              !output.existsSync();
        })
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
      message: 'Planning local mirror',
      detail: metadataOnly
          ? 'Backup metadata needs an update. ${_countLabel(requiredDirectories.length, 'folder')} needed.'
          : '${_countLabel(changedFiles.length, 'changed mirror file')}, ${_countLabel(staleFiles.length, 'stale file')} to remove, ${_countLabel(requiredDirectories.length, 'folder')} to verify.',
      progress: 0.16,
      processedCount: processedSteps,
      totalCount: totalSteps,
      entityCount: workspace.nodeCount,
      fileCount: workspace.fileCount,
    );

    for (final path in staleFiles) {
      _emitProgress(
        onProgress,
        message: 'Cleaning local mirror',
        detail: 'Deleting stale file $path.',
        progress: _stepProgress(processedSteps, totalSteps, 0.16, 0.24),
        processedCount: processedSteps,
        totalCount: totalSteps,
        entityCount: workspace.nodeCount,
        fileCount: workspace.fileCount,
      );
      await _deleteFile(root, path);
      processedSteps += 1;
    }

    final directories = requiredDirectories.toList(growable: false)
      ..sort((a, b) => a.length.compareTo(b.length));
    for (final directory in directories) {
      _emitProgress(
        onProgress,
        message: 'Creating local folders',
        detail: 'Ensuring $directory exists.',
        progress: _stepProgress(processedSteps, totalSteps, 0.24, 0.38),
        processedCount: processedSteps,
        totalCount: totalSteps,
        entityCount: workspace.nodeCount,
        fileCount: workspace.fileCount,
      );
      await Directory(_resolve(root, directory)).create(recursive: true);
      processedSteps += 1;
    }

    for (final file in changedFiles) {
      _emitProgress(
        onProgress,
        message: metadataOnly
            ? 'Writing backup metadata'
            : 'Writing local files',
        detail: metadataOnly
            ? 'Updating local mirror metadata.'
            : 'Writing ${file.relativePath}.',
        progress: _stepProgress(processedSteps, totalSteps, 0.38, 0.92),
        processedCount: processedSteps,
        totalCount: totalSteps,
        entityCount: workspace.nodeCount,
        fileCount: workspace.fileCount,
      );
      final output = File(_resolve(root, file.relativePath));
      await output.parent.create(recursive: true);
      final tmp = File('${output.path}.tmp');
      await _writeMirrorFile(tmp, file);
      if (output.existsSync()) {
        await output.delete();
      }
      await tmp.rename(output.path);
      processedSteps += 1;
    }

    _emitProgress(
      onProgress,
      message: 'Writing local manifest',
      detail: 'Saving metadata manifest and checksums.',
      progress: 0.94,
      processedCount: processedSteps,
      totalCount: totalSteps,
      entityCount: workspace.nodeCount,
      fileCount: workspace.fileCount,
    );
    final manifestFile = File(
      _resolve(root, VaultMirrorWorkspace.manifestPath),
    );
    await manifestFile.parent.create(recursive: true);
    await manifestFile.writeAsString(workspace.manifestText, flush: true);
    processedSteps += 1;

    for (final path in staleDirectories) {
      _emitProgress(
        onProgress,
        message: 'Cleaning local folders',
        detail: 'Deleting stale folder $path.',
        progress: 0.97,
        processedCount: processedSteps,
        totalCount: totalSteps,
        entityCount: workspace.nodeCount,
        fileCount: workspace.fileCount,
      );
      await _deleteEmptyDirectory(root, path);
      processedSteps += 1;
    }

    _emitProgress(
      onProgress,
      message: 'Local mirror complete',
      detail: metadataOnly
          ? 'Updated backup metadata and verified ${_countLabel(directories.length, 'folder')}.'
          : 'Wrote ${_countLabel(changedFiles.length, 'changed mirror file')} and verified ${_countLabel(directories.length, 'folder')}.',
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
      manifestPath: manifestFile.path,
      warningMessage: workspace.warningMessage,
    );
  }

  Future<void> _writeMirrorFile(File destination, VaultMirrorFile file) async {
    if (file.isInline) {
      await destination.writeAsBytes(await file.readBytes(), flush: true);
      return;
    }

    final sink = destination.openWrite();
    try {
      await file.openRead().pipe(sink);
    } catch (_) {
      await sink.close();
      rethrow;
    }
  }

  Future<VaultMirrorManifest> _readManifest(Directory root) async {
    final file = File(_resolve(root, VaultMirrorWorkspace.manifestPath));
    if (!file.existsSync()) {
      return VaultMirrorManifest.empty();
    }
    try {
      return VaultMirrorManifest.fromJsonText(await file.readAsString());
    } catch (_) {
      return VaultMirrorManifest.empty();
    }
  }

  Future<String> _hashText(String text) async {
    final hash = await Sha256().hash(utf8.encode(text));
    return hash.bytes.map((it) => it.toRadixString(16).padLeft(2, '0')).join();
  }

  Future<void> _deleteFile(Directory root, String relativePath) async {
    final file = File(_resolve(root, relativePath));
    if (!file.existsSync()) {
      return;
    }
    try {
      await file.delete();
    } catch (_) {
      // Leave locked files untouched; the next sync can try again.
    }
  }

  Future<void> _deleteEmptyDirectory(
    Directory root,
    String relativePath,
  ) async {
    final directory = Directory(_resolve(root, relativePath));
    if (!directory.existsSync()) {
      return;
    }
    try {
      if (directory.listSync().isEmpty) {
        await directory.delete();
      }
    } catch (_) {
      // Do not delete non-empty or provider-locked directories.
    }
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
    if (normalized.isEmpty || !normalized.contains('/')) {
      return <String>{};
    }
    final parts = normalized
        .split('/')
        .where((part) => part.isNotEmpty && part != '.' && part != '..')
        .toList(growable: false);
    final directories = <String>{};
    for (var i = 1; i < parts.length; i++) {
      directories.add(parts.take(i).join('/'));
    }
    return directories;
  }

  String _resolve(Directory root, String relativePath) {
    final rootUri = root.absolute.uri;
    final encoded = relativePath
        .trim()
        .replaceAll('\\', '/')
        .split('/')
        .where((part) => part.isNotEmpty && part != '.' && part != '..')
        .map(Uri.encodeComponent)
        .join('/');
    final outputUri = rootUri.resolve(encoded).normalizePath();
    final output = outputUri.toFilePath();
    final rootPath = rootUri.normalizePath().toFilePath();
    if (!output.startsWith(rootPath)) {
      throw StateError('Unsafe mirror path: $relativePath');
    }
    return output;
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
    onProgress?.call(
      VaultSyncProgressEntity(
        message: message,
        detail: detail,
        progress: progress.clamp(0, 1).toDouble(),
        processedCount: processedCount,
        totalCount: totalCount,
        entityCount: entityCount,
        fileCount: fileCount,
      ),
    );
  }

  String _countLabel(int count, String singular, [String? plural]) {
    return '$count ${count == 1 ? singular : plural ?? '${singular}s'}';
  }

  bool _isMirrorMetadataFile(String path) {
    return path == VaultMirrorWorkspace.snapshotPath;
  }
}
