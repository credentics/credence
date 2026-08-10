import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:pass_doc_manager/data/vault_sync/datasources/local/local_folder_sync_data_source.dart';
import 'package:pass_doc_manager/data/vault_sync/dtos/vault_sync_manifest_dto.dart';
import 'package:pass_doc_manager/data/vault_sync/dtos/vault_sync_remote_bundle_dto.dart';

class DropboxSyncDataSource {
  const DropboxSyncDataSource({required this.dio});

  final Dio dio;

  Future<VaultSyncRemoteBundleDto?> readBundle({
    required String accessToken,
    required String directoryPath,
  }) async {
    final manifestPath = _remoteFilePath(
      directoryPath: directoryPath,
      fileName: LocalFolderSyncDataSource.manifestFileName,
    );
    final snapshotPath = _remoteFilePath(
      directoryPath: directoryPath,
      fileName: LocalFolderSyncDataSource.snapshotFileName,
    );

    final manifestBytes = await _downloadBytesOrNull(
      accessToken: accessToken,
      remotePath: manifestPath,
    );
    if (manifestBytes == null) {
      return null;
    }

    final snapshotBytes = await _downloadBytesOrNull(
      accessToken: accessToken,
      remotePath: snapshotPath,
    );
    if (snapshotBytes == null) {
      return null;
    }

    final manifestText = utf8.decode(manifestBytes);
    final manifest = VaultSyncManifestDto.fromJsonText(manifestText);

    return VaultSyncRemoteBundleDto(
      manifest: manifest,
      encryptedPayload: snapshotBytes,
    );
  }

  Future<void> writeBundle({
    required String accessToken,
    required String directoryPath,
    required VaultSyncManifestDto manifest,
    required List<int> encryptedPayload,
  }) async {
    final snapshotPath = _remoteFilePath(
      directoryPath: directoryPath,
      fileName: LocalFolderSyncDataSource.snapshotFileName,
    );
    final manifestPath = _remoteFilePath(
      directoryPath: directoryPath,
      fileName: LocalFolderSyncDataSource.manifestFileName,
    );

    await _uploadBytes(
      accessToken: accessToken,
      remotePath: snapshotPath,
      bytes: encryptedPayload,
    );
    await _uploadBytes(
      accessToken: accessToken,
      remotePath: manifestPath,
      bytes: utf8.encode(manifest.toJsonText()),
    );
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
          headers: {
            'Authorization': 'Bearer ${accessToken.trim()}',
            'Dropbox-API-Arg': jsonEncode({'path': remotePath}),
          },
        ),
      );
      return response.data;
    } on DioException catch (e) {
      if (e.response?.statusCode == 409) {
        return null;
      }
      rethrow;
    }
  }

  Future<void> _uploadBytes({
    required String accessToken,
    required String remotePath,
    required List<int> bytes,
  }) async {
    await dio.post<void>(
      'https://content.dropboxapi.com/2/files/upload',
      data: bytes,
      options: Options(
        contentType: 'application/octet-stream',
        headers: {
          'Authorization': 'Bearer ${accessToken.trim()}',
          'Dropbox-API-Arg': jsonEncode({
            'path': remotePath,
            'mode': 'overwrite',
            'autorename': false,
            'mute': true,
            'strict_conflict': false,
          }),
        },
      ),
    );
  }

  String _remoteFilePath({
    required String directoryPath,
    required String fileName,
  }) {
    final dir = directoryPath.trim().isEmpty
        ? '/vaultmark_sync'
        : directoryPath.trim();
    final normalized = dir.startsWith('/') ? dir : '/$dir';
    return '$normalized/$fileName';
  }
}
