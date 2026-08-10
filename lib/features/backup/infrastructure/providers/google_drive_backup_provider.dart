import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'package:pass_doc_manager/features/backup/infrastructure/providers/remote_storage_provider.dart';

/// Google Drive implementation of [RemoteStorageProvider].
///
/// Uses the Google Drive REST API v3 with an OAuth 2.0 access token.
/// Files are organized under a **Credence / backups** folder hierarchy.
class GoogleDriveBackupProvider implements RemoteStorageProvider {
  GoogleDriveBackupProvider({
    required this.dio,
    required this.accessToken,
  });

  final Dio dio;
  final String accessToken;

  /// Root folder name used in Google Drive.
  static const String _rootFolderName = 'Credence';

  /// Subfolder that holds backup archives.
  static const String _backupsFolderName = 'backups';

  static const String _driveApiBase = 'https://www.googleapis.com/drive/v3';
  static const String _uploadApiBase =
      'https://www.googleapis.com/upload/drive/v3';

  /// Cached ID of the "Credence/backups" folder on Drive.
  String? _backupsFolderId;

  // ---------------------------------------------------------------------------
  // RemoteStorageProvider
  // ---------------------------------------------------------------------------

  @override
  Future<void> uploadFile({
    required String remotePath,
    required Uint8List bytes,
  }) async {
    final folderId = await _getOrCreateBackupsFolder();
    final fileName = _extractFileName(remotePath);

    // Check if a file with the same name already exists — overwrite it.
    final existingId = await _findFileIdByName(fileName, folderId);
    if (existingId != null) {
      // Update existing file content.
      await dio.patch<void>(
        '$_uploadApiBase/files/$existingId?uploadType=media',
        data: bytes,
        options: Options(
          contentType: 'application/octet-stream',
          headers: _authHeader,
        ),
      );
      return;
    }

    // Step 1: Create a file metadata entry (no content yet).
    final createResponse = await dio.post<Map<String, dynamic>>(
      '$_driveApiBase/files',
      data: jsonEncode({
        'name': fileName,
        'parents': [folderId],
      }),
      options: Options(
        contentType: 'application/json',
        headers: _authHeader,
      ),
    );
    final fileId = createResponse.data!['id'] as String;

    // Step 2: Upload content to the created file.
    await dio.patch<void>(
      '$_uploadApiBase/files/$fileId?uploadType=media',
      data: bytes,
      options: Options(
        contentType: 'application/octet-stream',
        headers: _authHeader,
      ),
    );
  }

  @override
  Future<Uint8List> downloadFile({required String remotePath}) async {
    final folderId = await _getOrCreateBackupsFolder();
    final fileName = _extractFileName(remotePath);

    final fileId = await _findFileIdByName(fileName, folderId);
    if (fileId == null) {
      throw StateError(
        'Google Drive file not found: $remotePath',
      );
    }

    final response = await dio.get<List<int>>(
      '$_driveApiBase/files/$fileId',
      queryParameters: {'alt': 'media'},
      options: Options(
        responseType: ResponseType.bytes,
        headers: _authHeader,
      ),
    );

    final data = response.data;
    if (data == null) {
      throw StateError('Google Drive download returned null for $remotePath');
    }
    return Uint8List.fromList(data);
  }

  @override
  Future<List<RemoteFileInfo>> listFiles({required String directory}) async {
    final folderId = await _getOrCreateBackupsFolder();
    final results = <RemoteFileInfo>[];
    String? pageToken;

    do {
      final queryParams = <String, dynamic>{
        'q': "'$folderId' in parents and trashed=false",
        'fields': 'nextPageToken,files(id,name,size,modifiedTime)',
        'pageSize': 1000,
      };
      if (pageToken != null) {
        queryParams['pageToken'] = pageToken;
      }

      final response = await dio.get<Map<String, dynamic>>(
        '$_driveApiBase/files',
        queryParameters: queryParams,
        options: Options(headers: _authHeader),
      );

      final data = response.data ?? {};
      final files = (data['files'] as List<dynamic>?) ?? [];

      for (final entry in files) {
        final map = entry as Map<String, dynamic>;
        results.add(
          RemoteFileInfo(
            remotePath: map['name'] as String? ?? '',
            sizeBytes: int.tryParse('${map['size'] ?? '0'}') ?? 0,
            modifiedAt: DateTime.tryParse(
                  map['modifiedTime'] as String? ?? '',
                ) ??
                DateTime.now(),
          ),
        );
      }

      pageToken = data['nextPageToken'] as String?;
    } while (pageToken != null);

    return results;
  }

  @override
  Future<void> deleteFile({required String remotePath}) async {
    final folderId = await _getOrCreateBackupsFolder();
    final fileName = _extractFileName(remotePath);

    final fileId = await _findFileIdByName(fileName, folderId);
    if (fileId == null) {
      debugPrint('[GoogleDrive] File not found for deletion: $remotePath');
      return;
    }

    await dio.delete<void>(
      '$_driveApiBase/files/$fileId',
      options: Options(headers: _authHeader),
    );
  }

  @override
  Future<bool> fileExists({required String remotePath}) async {
    final folderId = await _getOrCreateBackupsFolder();
    final fileName = _extractFileName(remotePath);
    final fileId = await _findFileIdByName(fileName, folderId);
    return fileId != null;
  }

  // ---------------------------------------------------------------------------
  // Folder management
  // ---------------------------------------------------------------------------

  /// Returns the Google Drive folder ID for `Credence/backups`, creating the
  /// hierarchy if it does not yet exist.
  Future<String> _getOrCreateBackupsFolder() async {
    if (_backupsFolderId != null) return _backupsFolderId!;

    final rootId =
        await _findFolder(name: _rootFolderName, parentId: 'root') ??
        await _findOrCreateFolder(name: _rootFolderName, parentId: 'root');
    _backupsFolderId = await _findOrCreateFolder(
      name: _backupsFolderName,
      parentId: rootId,
    );
    return _backupsFolderId!;
  }

  /// Searches for a folder with [name] under [parentId]; returns its id or null.
  Future<String?> _findFolder({
    required String name,
    required String parentId,
  }) async {
    final query = "name='$name' "
        "and mimeType='application/vnd.google-apps.folder' "
        "and '$parentId' in parents "
        "and trashed=false";
    final searchResponse = await dio.get<Map<String, dynamic>>(
      '$_driveApiBase/files',
      queryParameters: {
        'q': query,
        'fields': 'files(id)',
        'pageSize': 1,
      },
      options: Options(headers: _authHeader),
    );
    final files = (searchResponse.data?['files'] as List<dynamic>?) ?? [];
    if (files.isNotEmpty) {
      return (files.first as Map<String, dynamic>)['id'] as String;
    }
    return null;
  }

  /// Finds a folder with [name] under [parentId], or creates it.
  Future<String> _findOrCreateFolder({
    required String name,
    required String parentId,
  }) async {
    final existing = await _findFolder(name: name, parentId: parentId);
    if (existing != null) {
      return existing;
    }

    // Create the folder.
    final createResponse = await dio.post<Map<String, dynamic>>(
      '$_driveApiBase/files',
      data: jsonEncode({
        'name': name,
        'mimeType': 'application/vnd.google-apps.folder',
        'parents': [parentId],
      }),
      options: Options(
        contentType: 'application/json',
        headers: _authHeader,
      ),
    );

    return createResponse.data!['id'] as String;
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  Map<String, String> get _authHeader => {
        'Authorization': 'Bearer ${accessToken.trim()}',
      };

  /// Looks up a file by [name] inside a given [parentFolderId].
  /// Returns the Google Drive file ID or `null`.
  Future<String?> _findFileIdByName(
    String name,
    String parentFolderId,
  ) async {
    final query = "name='$name' "
        "and '$parentFolderId' in parents "
        "and trashed=false";

    final response = await dio.get<Map<String, dynamic>>(
      '$_driveApiBase/files',
      queryParameters: {
        'q': query,
        'fields': 'files(id)',
        'pageSize': 1,
      },
      options: Options(headers: _authHeader),
    );

    final files =
        (response.data?['files'] as List<dynamic>?) ?? [];
    if (files.isEmpty) return null;
    return (files.first as Map<String, dynamic>)['id'] as String;
  }

  /// Extracts the file name from a path-like remote path
  /// (e.g. `/Credence/backups/foo.enc` -> `foo.enc`).
  String _extractFileName(String remotePath) {
    final segments = remotePath.split('/');
    return segments.last;
  }
}
