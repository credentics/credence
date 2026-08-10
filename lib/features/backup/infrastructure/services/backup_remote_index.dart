import 'dart:convert';
import 'dart:typed_data';

import 'package:pass_doc_manager/features/backup/data/dtos/backup_manifest_dto.dart';
import 'package:pass_doc_manager/features/backup/domain/entities/backup_manifest.dart';
import 'package:pass_doc_manager/features/backup/infrastructure/providers/remote_storage_provider.dart';

class BackupRemoteIndex {
  static const String backupsDir = '/Credence/backups';
  static const String indexPath = '$backupsDir/index.json';

  /// Reads the remote index.
  Future<BackupRemoteIndexData?> read(RemoteStorageProvider provider) async {
    try {
      final bytes = await provider.downloadFile(remotePath: indexPath);
      final json = jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
      return BackupRemoteIndexData.fromMap(json);
    } catch (_) {
      return null;
    }
  }

  /// Writes the remote index to the new location.
  Future<void> write(
    RemoteStorageProvider provider,
    BackupRemoteIndexData data,
  ) async {
    final bytes = Uint8List.fromList(utf8.encode(jsonEncode(data.toMap())));
    await provider.uploadFile(remotePath: indexPath, bytes: bytes);
  }

  /// Reconstructs the index by listing manifest files in the backup directory.
  Future<BackupRemoteIndexData> reconstruct(
    RemoteStorageProvider provider,
  ) async {
    final manifests = <BackupManifest>[];
    final files = await () async {
      try {
        return await provider.listFiles(directory: backupsDir);
      } catch (_) {
        return null;
      }
    }();
    for (final file in files ?? const []) {
      if (!file.remotePath.endsWith('.manifest.json')) continue;
      try {
        final bytes = await provider.downloadFile(remotePath: file.remotePath);
        final json = jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
        manifests.add(BackupManifestDto.fromMap(json).toEntity());
      } catch (_) {
        continue;
      }
    }
    return BackupRemoteIndexData(
      indexVersion: 1,
      lastUpdatedAt: DateTime.now().toUtc(),
      backups: manifests,
    );
  }
}

class BackupRemoteIndexData {
  const BackupRemoteIndexData({
    required this.indexVersion,
    required this.lastUpdatedAt,
    required this.backups,
  });

  factory BackupRemoteIndexData.fromMap(Map<String, dynamic> map) {
    final backupsRaw = map['backups'] as List? ?? [];
    return BackupRemoteIndexData(
      indexVersion: map['index_version'] as int? ?? 1,
      lastUpdatedAt:
          DateTime.tryParse(map['last_updated_at'] as String? ?? '') ??
              DateTime.now(),
      backups: backupsRaw
          .whereType<Map>()
          .map(
            (m) => BackupManifestDto.fromMap(Map<String, dynamic>.from(m))
                .toEntity(),
          )
          .toList(),
    );
  }

  final int indexVersion;
  final DateTime lastUpdatedAt;
  final List<BackupManifest> backups;

  Map<String, dynamic> toMap() {
    return {
      'index_version': indexVersion,
      'last_updated_at': lastUpdatedAt.toIso8601String(),
      'backups': backups
          .map((b) => BackupManifestDto.fromEntity(b).toMap())
          .toList(),
    };
  }
}
