import 'dart:io';

import 'package:pass_doc_manager/data/vault_sync/dtos/vault_sync_manifest_dto.dart';
import 'package:pass_doc_manager/data/vault_sync/dtos/vault_sync_remote_bundle_dto.dart';

class LocalFolderSyncDataSource {
  static const snapshotFileName = 'vaultmark_snapshot.enc';
  static const manifestFileName = 'vaultmark_manifest.json';

  Future<VaultSyncRemoteBundleDto?> readBundle({
    required String folderPath,
  }) async {
    final cleaned = folderPath.trim();
    if (cleaned.isEmpty) {
      return null;
    }

    final directory = Directory(cleaned);
    if (!directory.existsSync()) {
      return null;
    }

    final manifestFile = File('${directory.path}/$manifestFileName');
    final snapshotFile = File('${directory.path}/$snapshotFileName');
    if (!manifestFile.existsSync() || !snapshotFile.existsSync()) {
      return null;
    }

    final manifestText = await manifestFile.readAsString();
    final manifest = VaultSyncManifestDto.fromJsonText(manifestText);
    final payload = await snapshotFile.readAsBytes();

    return VaultSyncRemoteBundleDto(
      manifest: manifest,
      encryptedPayload: payload,
    );
  }

  Future<void> writeBundle({
    required String folderPath,
    required VaultSyncManifestDto manifest,
    required List<int> encryptedPayload,
  }) async {
    final cleaned = folderPath.trim();
    if (cleaned.isEmpty) {
      throw const FileSystemException('Local sync folder path is empty.');
    }

    final directory = Directory(cleaned);
    if (!directory.existsSync()) {
      await directory.create(recursive: true);
    }

    final manifestFile = File('${directory.path}/$manifestFileName');
    final snapshotFile = File('${directory.path}/$snapshotFileName');

    await _atomicWriteBytes(snapshotFile, encryptedPayload);
    await _atomicWriteString(manifestFile, manifest.toJsonText());
  }

  Future<void> _atomicWriteBytes(File destination, List<int> bytes) async {
    final tmp = File('${destination.path}.tmp');
    await tmp.writeAsBytes(bytes, flush: true);
    if (destination.existsSync()) {
      await destination.delete();
    }
    await tmp.rename(destination.path);
  }

  Future<void> _atomicWriteString(File destination, String text) async {
    final tmp = File('${destination.path}.tmp');
    await tmp.writeAsString(text, flush: true);
    if (destination.existsSync()) {
      await destination.delete();
    }
    await tmp.rename(destination.path);
  }
}
