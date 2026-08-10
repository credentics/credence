import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pass_doc_manager/data/vault_sync/mirror/local_folder_mirror_data_source.dart';
import 'package:pass_doc_manager/data/vault_sync/mirror/vault_mirror_import_service.dart';
import 'package:pass_doc_manager/data/vault_sync/mirror/vault_mirror_workspace.dart';
import 'package:pass_doc_manager/data/vault_sync/mirror/vault_mirror_import_source.dart';
import 'package:pass_doc_manager/data/vault_sync/mirror/vault_mirror_workspace_builder.dart';
import 'package:pass_doc_manager/features/backup/data/datasources/local/backup_local_data_source.dart';
import 'package:pass_doc_manager/features/backup/data/dtos/backup_manifest_dto.dart';
import 'package:pass_doc_manager/features/backup/domain/entities/backup_chain.dart';
import 'package:pass_doc_manager/features/backup/domain/entities/backup_manifest.dart';
import 'package:pass_doc_manager/features/backup/domain/entities/backup_operation_progress.dart';
import 'package:pass_doc_manager/features/backup/domain/entities/backup_type.dart';
import 'package:pass_doc_manager/features/backup/domain/entities/device_identity.dart';
import 'package:pass_doc_manager/features/backup/domain/repositories/backup_repository.dart';
import 'package:pass_doc_manager/features/backup/infrastructure/providers/dropbox_backup_provider.dart';
import 'package:pass_doc_manager/features/backup/infrastructure/providers/remote_storage_provider.dart';
import 'package:dio/dio.dart';
import 'package:pass_doc_manager/features/backup/infrastructure/services/backup_archive_service.dart';
import 'package:pass_doc_manager/features/backup/infrastructure/services/backup_chain_manager.dart';
import 'package:pass_doc_manager/features/backup/infrastructure/services/backup_crypto_service.dart';
import 'package:pass_doc_manager/features/backup/infrastructure/services/backup_integrity_service.dart';
import 'package:pass_doc_manager/features/backup/infrastructure/services/backup_remote_index.dart';
import 'package:pass_doc_manager/features/backup/infrastructure/services/backup_replay_engine.dart';

class BackupRepositoryImpl implements BackupRepository {
  BackupRepositoryImpl({
    required this.localDataSource,
    required this.archiveService,
    required this.cryptoService,
    required this.integrityService,
    required this.chainManager,
    required this.replayEngine,
    required this.mirrorBuilder,
    required this.localMirrorDataSource,
    required this.mirrorImportService,
    this.remoteProvider,
  });

  final BackupLocalDataSource localDataSource;
  final BackupArchiveService archiveService;
  final BackupCryptoService cryptoService;
  final BackupIntegrityService integrityService;
  final BackupChainManager chainManager;
  final BackupReplayEngine replayEngine;
  final VaultMirrorWorkspaceBuilder mirrorBuilder;
  final LocalFolderMirrorDataSource localMirrorDataSource;
  final VaultMirrorImportService mirrorImportService;
  final RemoteStorageProvider? remoteProvider;

  static const int _schemaVersion = 1;
  static const int _manifestVersion = 1;
  static const String _backupsDir = 'local_backups';
  static const String _mirrorBackupsDir = 'local_backups/vault_mirror';

  @override
  Future<BackupManifest> createBackup({
    required String passphrase,
    BackupOperationProgressCallback? onProgress,
  }) async {
    _emitProgress(
      onProgress,
      message: 'Preparing backup',
      detail: 'Loading device info and determining the next backup type.',
      progress: 0.03,
    );
    final device = await getDeviceIdentity();
    final chain = await getActiveChain();
    final hasPassphrase = passphrase.trim().isNotEmpty;
    debugPrint(
      '[Backup] Creating mirror backup '
      '(passphrase ${hasPassphrase ? 'provided' : 'not provided'}, '
      'streaming mode)',
    );

    _emitProgress(
      onProgress,
      message: 'Building mirror',
      detail: 'Preparing the vault folder structure and metadata manifest.',
      progress: 0.18,
    );
    final revision = (chain.isEmpty ? 0 : chain.depth) + 1;
    final workspace = await mirrorBuilder.build(
      deviceId: device.deviceId,
      revision: revision,
    );
    debugPrint(
      '[Backup] Mirror workspace: '
      '${workspace.fileCount} files, '
      '${workspace.directoryCount} folders, '
      '${workspace.nodeCount} nodes, '
      '${_formatBytes(workspace.byteCount)}',
    );

    _emitProgress(
      onProgress,
      message: 'Writing mirror backup',
      detail: 'Streaming files and metadata to the local backup mirror.',
      progress: 0.62,
      entityCount: workspace.nodeCount,
      fileCount: workspace.fileCount,
    );
    final mirrorDir = await _mirrorBackupsDirectory();
    final result = await localMirrorDataSource.writeWorkspace(
      folderPath: mirrorDir.path,
      workspace: workspace,
    );
    debugPrint(
      '[Backup] Mirror written: ${result.manifestPath} '
      '(${result.fileCount} files, ${_formatBytes(result.byteCount)})',
    );
    if ((result.warningMessage ?? '').trim().isNotEmpty) {
      debugPrint('[Backup] Mirror warning: ${result.warningMessage}');
    }

    final now = DateTime.now().toUtc();
    final latestSeq = await localDataSource.getLatestSequence();
    final backupId =
        'bk_${now.toIso8601String().replaceAll(RegExp(r'[:\-.]'), '')}_mirror_${device.deviceId.substring(0, 8)}';

    final manifest = BackupManifest(
      manifestVersion: _manifestVersion,
      backupId: backupId,
      backupType: BackupType.full,
      parentBackupId: chain.head?.backupId,
      deviceId: device.deviceId,
      deviceName: device.deviceName,
      appVersion: device.appVersion,
      schemaVersion: _schemaVersion,
      createdAt: now,
      journalFromSequence: chain.head?.journalToSequence ?? 0,
      journalToSequence: latestSeq,
      entityCount: workspace.nodeCount,
      fileCount: workspace.fileCount,
      tombstoneCount: 0,
      archiveSizeBytes: workspace.byteCount,
      archiveHash: workspace.manifestChecksum,
      chainDepth: (chain.isEmpty ? 0 : chain.depth) + 1,
      remoteFileName: result.manifestPath,
      warningMessage: result.warningMessage,
    );

    _emitProgress(
      onProgress,
      message: 'Saving backup metadata',
      detail: 'Recording the latest mirror backup state.',
      progress: 0.9,
      entityCount: workspace.nodeCount,
      fileCount: workspace.fileCount,
    );
    await localDataSource.saveLocalManifest(
      BackupManifestDto.fromEntity(manifest).toMap(),
    );
    await localDataSource.updateChainState({
      'chain_id': chain.isEmpty ? backupId : chain.chainId,
      'base_backup_id': chain.isEmpty ? backupId : chain.baseBackupId,
      'head_backup_id': backupId,
      'depth': manifest.chainDepth,
      'device_id': device.deviceId,
    });

    _emitProgress(
      onProgress,
      message: result.warningMessage == null
          ? 'Backup complete'
          : 'Backup complete with warnings',
      detail:
          result.warningMessage ??
          'The vault mirror is up to date without loading files in memory.',
      progress: 1,
      entityCount: workspace.nodeCount,
      fileCount: workspace.fileCount,
    );
    debugPrint(
      '[Backup] Created mirror $backupId '
      '(${_formatBytes(manifest.archiveSizeBytes)})',
    );
    return manifest;
  }

  @override
  Future<void> restoreFromBackup({
    required String backupId,
    required String passphrase,
    BackupOperationProgressCallback? onProgress,
  }) async {
    debugPrint('[Restore] Starting restore from $backupId');

    _emitProgress(
      onProgress,
      message: 'Opening backup archive',
      detail: 'Loading the selected encrypted backup from local storage.',
      progress: 0.04,
    );
    final encryptedBytes = await _loadBackupLocally(backupId);
    if (encryptedBytes == null) {
      final restored = await _restoreLocalMirrorBackup(
        backupId: backupId,
        onProgress: onProgress,
      );
      if (restored) {
        return;
      }
      throw StateError('Backup $backupId not found locally');
    }

    _emitProgress(
      onProgress,
      message: 'Reading backup manifest',
      detail: 'Inspecting metadata for the selected restore point.',
      progress: 0.1,
    );
    final manifests = await localDataSource.getLocalManifests();
    final manifestMap = manifests.firstWhere(
      (m) => m['backup_id'] == backupId,
      orElse: () => throw StateError('Manifest not found for $backupId'),
    );
    final manifest = BackupManifestDto.fromMap(manifestMap).toEntity();

    _emitProgress(
      onProgress,
      message: 'Validating archive',
      detail: 'Checking backup integrity before decrypting anything.',
      progress: 0.18,
    );
    final isValid = await integrityService.validateArchiveBytes(
      encryptedBytes,
      manifest.archiveHash,
    );
    if (!isValid) {
      throw StateError('Archive hash mismatch — backup may be corrupted');
    }

    _emitProgress(
      onProgress,
      message: 'Decrypting backup',
      detail: 'Unlocking the archive with the provided passphrase.',
      progress: 0.28,
    );
    final decrypted = await cryptoService.decrypt(
      ciphertext: encryptedBytes,
      passphrase: passphrase,
      salt: manifest.salt!,
      nonce: manifest.nonce!,
    );

    _emitProgress(
      onProgress,
      message: 'Unpacking archive',
      detail:
          'Reading encrypted records, files, and saved state from the archive.',
      progress: 0.38,
    );
    final archiveFiles = archiveService.extractArchive(decrypted);

    await replayEngine.restoreFromArchive(
      archiveFiles,
      onProgress: (progress) {
        _emitProgress(
          onProgress,
          progress: _mapProgress(progress.progress, 0.42, 1.0),
          message: progress.message,
          detail: progress.detail,
          processedCount: progress.processedCount,
          totalCount: progress.totalCount,
          entityCount: progress.entityCount,
          fileCount: progress.fileCount,
        );
      },
    );

    debugPrint('[Restore] Completed successfully');
  }

  Future<bool> _restoreLocalMirrorBackup({
    required String backupId,
    BackupOperationProgressCallback? onProgress,
  }) async {
    final manifests = await localDataSource.getLocalManifests();
    final manifestMap = manifests.firstWhere(
      (m) => m['backup_id'] == backupId,
      orElse: () => const <String, dynamic>{},
    );
    if (manifestMap.isEmpty) {
      return false;
    }
    final remoteFileName = '${manifestMap['remote_file_name'] ?? ''}'.trim();
    final normalizedRemote = remoteFileName.replaceAll('\\', '/');
    if (!normalizedRemote.endsWith('/${VaultMirrorWorkspace.manifestPath}')) {
      return false;
    }
    final manifestFile = File(remoteFileName);
    final mirrorRoot = manifestFile.parent.parent;
    if (!manifestFile.existsSync() || !mirrorRoot.existsSync()) {
      return false;
    }

    _emitProgress(
      onProgress,
      message: 'Opening mirror backup',
      detail: 'Restoring the local folder mirror without decrypting archives.',
      progress: 0.06,
    );
    await mirrorImportService.importFromSource(
      source: LocalFolderVaultMirrorImportSource(folderPath: mirrorRoot.path),
      onProgress: (progress) => _emitProgress(
        onProgress,
        message: progress.message,
        detail: progress.detail,
        progress: progress.progress,
        processedCount: progress.processedCount,
        totalCount: progress.totalCount,
        entityCount: progress.entityCount,
        fileCount: progress.fileCount,
      ),
    );
    debugPrint('[Restore] Completed local mirror restore');
    return true;
  }

  @override
  Future<void> restoreFromCloudDownload({
    required List<int> encryptedBytes,
    required String passphrase,
    required Map<String, dynamic> manifestMap,
    BackupOperationProgressCallback? onProgress,
  }) async {
    debugPrint('[CloudRestore] Decrypting ${encryptedBytes.length} bytes...');

    final manifest = BackupManifestDto.fromMap(manifestMap).toEntity();
    final bytes = Uint8List.fromList(encryptedBytes);

    _emitProgress(
      onProgress,
      message: 'Validating cloud backup',
      detail: 'Checking the downloaded archive before restoring it.',
      progress: 0.18,
    );
    final isValid = await integrityService.validateArchiveBytes(
      bytes,
      manifest.archiveHash,
    );
    if (!isValid) {
      throw StateError('Archive hash mismatch — cloud backup may be corrupted');
    }

    _emitProgress(
      onProgress,
      message: 'Decrypting cloud backup',
      detail: 'Unlocking the downloaded archive with your passphrase.',
      progress: 0.28,
    );
    final decrypted = await cryptoService.decrypt(
      ciphertext: bytes,
      passphrase: passphrase,
      salt: manifest.salt!,
      nonce: manifest.nonce!,
    );

    _emitProgress(
      onProgress,
      message: 'Unpacking cloud backup',
      detail: 'Reading the downloaded archive contents.',
      progress: 0.38,
    );
    final archiveFiles = archiveService.extractArchive(decrypted);
    await replayEngine.restoreFromArchive(
      archiveFiles,
      onProgress: (progress) {
        _emitProgress(
          onProgress,
          progress: _mapProgress(progress.progress, 0.42, 1.0),
          message: progress.message,
          detail: progress.detail,
          processedCount: progress.processedCount,
          totalCount: progress.totalCount,
          entityCount: progress.entityCount,
          fileCount: progress.fileCount,
        );
      },
    );

    debugPrint('[CloudRestore] Completed successfully');
  }

  @override
  Future<List<BackupManifest>> listBackups() async {
    final manifests = await localDataSource.getLocalManifests();
    return manifests
        .map((m) => BackupManifestDto.fromMap(m).toEntity())
        .toList(growable: false)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  @override
  Future<void> deleteBackup(String backupId) async {
    await localDataSource.removeLocalManifest(backupId);
    final dir = await _backupsDirectory();
    final file = File('${dir.path}${Platform.pathSeparator}$backupId.enc');
    if (await file.exists()) {
      await file.delete();
    }
    debugPrint('[Backup] Deleted $backupId');
  }

  @override
  Future<BackupChain> getActiveChain() async {
    final state = await localDataSource.getChainState();
    if (state == null) {
      return const BackupChain(
        chainId: '',
        baseBackupId: '',
        headBackupId: '',
        depth: 0,
        deviceId: '',
        backups: [],
      );
    }

    final manifests = await listBackups();
    final chainId = state['chain_id'] as String? ?? '';
    final headId = state['head_backup_id'] as String? ?? '';

    if (headId.isEmpty) {
      return BackupChain(
        chainId: chainId,
        baseBackupId: state['base_backup_id'] as String? ?? '',
        headBackupId: '',
        depth: 0,
        deviceId: state['device_id'] as String? ?? '',
        backups: const [],
      );
    }

    final chain = chainManager.buildChain(headId, manifests);
    return chain ??
        BackupChain(
          chainId: chainId,
          baseBackupId: state['base_backup_id'] as String? ?? '',
          headBackupId: headId,
          depth: state['depth'] as int? ?? 0,
          deviceId: state['device_id'] as String? ?? '',
          backups: const [],
        );
  }

  @override
  Future<ChainValidationResult> validateChain() async {
    final chain = await getActiveChain();
    return chainManager.validateChain(chain);
  }

  @override
  Future<void> uploadPendingBackups({
    required String accessToken,
    void Function(int uploaded, int total, String fileName)? onProgress,
  }) async {
    final provider = DropboxBackupProvider(
      dio: Dio(),
      accessToken: accessToken,
    );

    final manifests = await localDataSource.getLocalManifests();
    // Each manifest produces 2 uploads (archive + manifest JSON)
    final totalFiles = manifests.length * 2;
    var uploadedFileCount = 0;
    var uploadedBackupCount = 0;

    for (final manifestMap in manifests) {
      final backupId = manifestMap['backup_id'] as String? ?? '';

      final bytes = await _loadBackupLocally(backupId);
      if (bytes == null) continue;

      final archiveName = '$backupId.enc';
      final remotePath = '${BackupRemoteIndex.backupsDir}/$archiveName';
      onProgress?.call(uploadedFileCount, totalFiles, archiveName);
      await provider.uploadFile(remotePath: remotePath, bytes: bytes);
      uploadedFileCount++;
      debugPrint(
        '[Upload] Uploaded archive: $remotePath (${bytes.length} bytes)',
      );

      // Upload manifest
      final manifestName = '$backupId.manifest.json';
      onProgress?.call(uploadedFileCount, totalFiles, manifestName);
      final manifestBytes = Uint8List.fromList(
        utf8.encode(jsonEncode(manifestMap)),
      );
      await provider.uploadFile(
        remotePath: '${BackupRemoteIndex.backupsDir}/$manifestName',
        bytes: manifestBytes,
      );
      uploadedFileCount++;
      uploadedBackupCount++;
    }

    onProgress?.call(totalFiles, totalFiles, 'done');
    debugPrint('[Upload] Done — $uploadedBackupCount backup(s) uploaded');

    // After all uploads, update the remote index
    try {
      final remoteIndex = BackupRemoteIndex();
      final allManifests = await listBackups();
      await remoteIndex.write(
        provider,
        BackupRemoteIndexData(
          indexVersion: 1,
          lastUpdatedAt: DateTime.now().toUtc(),
          backups: allManifests,
        ),
      );
      debugPrint('[Upload] Remote index updated');
    } catch (e) {
      debugPrint('[Upload] Failed to update remote index: $e');
      // Non-fatal — index is a cache
    }
  }

  /// Downloads a backup archive file, preferring the new `/Credence/backups`
  /// location.
  Future<Uint8List> _downloadArchiveFile(
    RemoteStorageProvider provider,
    String fileName,
  ) async {
    return provider.downloadFile(
      remotePath: '${BackupRemoteIndex.backupsDir}/$fileName',
    );
  }

  @override
  Future<void> downloadBackup({
    required String backupId,
    required String accessToken,
  }) async {
    if (remoteProvider == null) return;

    final bytes = await _downloadArchiveFile(
      remoteProvider!,
      '$backupId.enc',
    );

    final dir = await _backupsDirectory();
    final file = File('${dir.path}${Platform.pathSeparator}$backupId.enc');
    try {
      await file.writeAsBytes(bytes, flush: true);
    } on FileSystemException catch (e) {
      if (e.message.contains('No space') || e.osError?.errorCode == 28) {
        throw StateError(
          'Not enough disk space to download backup. Free up storage and try again.',
        );
      }
      rethrow;
    }

    // Download manifest
    final manifestBytes = await _downloadArchiveFile(
      remoteProvider!,
      '$backupId.manifest.json',
    );
    final manifestMap =
        jsonDecode(utf8.decode(manifestBytes)) as Map<String, dynamic>;
    await localDataSource.saveLocalManifest(manifestMap);

    debugPrint('[Download] Downloaded $backupId');
  }

  @override
  Future<DeviceIdentity> getDeviceIdentity() async {
    final existing = await localDataSource.getDeviceIdentity();
    if (existing != null) {
      return DeviceIdentity(
        deviceId: existing['device_id'] as String? ?? '',
        deviceName: existing['device_name'] as String? ?? '',
        platform: existing['platform'] as String? ?? '',
        firstSeenAt:
            DateTime.tryParse(existing['first_seen_at_iso'] as String? ?? '') ??
            DateTime.now(),
        appVersion: existing['app_version'] as String? ?? '',
      );
    }

    final now = DateTime.now().toUtc();
    final deviceId = 'device_${now.microsecondsSinceEpoch}';
    final platform = Platform.operatingSystem;
    final identity = DeviceIdentity(
      deviceId: deviceId,
      deviceName: '$platform device',
      platform: platform,
      firstSeenAt: now,
      appVersion: '1.0.0',
    );

    await localDataSource.saveDeviceIdentity({
      'device_id': identity.deviceId,
      'device_name': identity.deviceName,
      'platform': identity.platform,
      'first_seen_at_iso': identity.firstSeenAt.toIso8601String(),
      'app_version': identity.appVersion,
    });

    return identity;
  }

  // ── Local File Helpers ──

  Future<Directory> _backupsDirectory() async {
    final supportDir = await getApplicationSupportDirectory();
    final dir = Directory(
      '${supportDir.path}${Platform.pathSeparator}$_backupsDir',
    );
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  Future<Directory> _mirrorBackupsDirectory() async {
    final supportDir = await getApplicationSupportDirectory();
    final dir = Directory(
      '${supportDir.path}${Platform.pathSeparator}$_mirrorBackupsDir',
    );
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  Future<Uint8List?> _loadBackupLocally(String backupId) async {
    final dir = await _backupsDirectory();
    final file = File('${dir.path}${Platform.pathSeparator}$backupId.enc');
    if (!await file.exists()) return null;
    return file.readAsBytes();
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

  double? _mapProgress(double? value, double start, double end) {
    if (value == null) {
      return null;
    }
    final clamped = value.clamp(0.0, 1.0);
    return start + ((end - start) * clamped);
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
