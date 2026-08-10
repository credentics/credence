import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'package:pass_doc_manager/features/backup/infrastructure/providers/remote_storage_provider.dart';

/// Dropbox implementation of [RemoteStorageProvider].
///
/// Follows the same HTTP patterns used by [DropboxSyncDataSource] elsewhere in
/// the project.
class DropboxBackupProvider implements RemoteStorageProvider {
  const DropboxBackupProvider({required this.dio, required this.accessToken});

  final Dio dio;
  final String accessToken;

  // ---------------------------------------------------------------------------
  // RemoteStorageProvider
  // ---------------------------------------------------------------------------

  @override
  Future<void> uploadFile({
    required String remotePath,
    required Uint8List bytes,
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

  @override
  Future<Uint8List> downloadFile({required String remotePath}) async {
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

    final data = response.data;
    if (data == null) {
      throw StateError('Dropbox download returned null for $remotePath');
    }
    return Uint8List.fromList(data);
  }

  @override
  Future<List<RemoteFileInfo>> listFiles({required String directory}) async {
    final results = <RemoteFileInfo>[];
    String? cursor;
    var hasMore = true;

    // Initial request.
    final Response<Map<String, dynamic>> initialResponse;
    try {
      initialResponse = await dio.post<Map<String, dynamic>>(
        'https://api.dropboxapi.com/2/files/list_folder',
        data: jsonEncode({
          'path': directory,
          'recursive': false,
          'include_deleted': false,
        }),
        options: Options(
          contentType: 'application/json',
          headers: {'Authorization': 'Bearer ${accessToken.trim()}'},
        ),
      );
    } on DioException catch (e) {
      final body = e.response?.data;
      final status = e.response?.statusCode;
      debugPrint('[Dropbox] list_folder error $status: $body');

      // 409 = path not found (folder doesn't exist yet)
      if (status == 409) return const [];

      // 400/401 = missing scope or bad request — surface the error
      if (status == 400 || status == 401) {
        final errorStr = body is Map
            ? (body['error_summary'] as String? ?? '$body')
            : '$body';
        if (errorStr.contains('missing_scope') ||
            errorStr.contains('not permitted')) {
          throw StateError(
            'Dropbox permissions missing. Go to Dropbox App Console → Permissions tab → enable files.metadata.read and files.content.read, then reconnect.',
          );
        }
        return const [];
      }
      rethrow;
    }

    _parseListResponse(initialResponse.data!, results);
    cursor = initialResponse.data!['cursor'] as String?;
    hasMore = initialResponse.data!['has_more'] as bool? ?? false;

    // Paginate if needed.
    while (hasMore && cursor != null) {
      final continueResponse = await dio.post<Map<String, dynamic>>(
        'https://api.dropboxapi.com/2/files/list_folder/continue',
        data: jsonEncode({'cursor': cursor}),
        options: Options(
          contentType: 'application/json',
          headers: {'Authorization': 'Bearer ${accessToken.trim()}'},
        ),
      );

      _parseListResponse(continueResponse.data!, results);
      cursor = continueResponse.data!['cursor'] as String?;
      hasMore = continueResponse.data!['has_more'] as bool? ?? false;
    }

    return results;
  }

  @override
  Future<void> deleteFile({required String remotePath}) async {
    await dio.post<void>(
      'https://api.dropboxapi.com/2/files/delete_v2',
      data: jsonEncode({'path': remotePath}),
      options: Options(
        contentType: 'application/json',
        headers: {'Authorization': 'Bearer ${accessToken.trim()}'},
      ),
    );
  }

  @override
  Future<bool> fileExists({required String remotePath}) async {
    try {
      await dio.post<Map<String, dynamic>>(
        'https://api.dropboxapi.com/2/files/get_metadata',
        data: jsonEncode({'path': remotePath}),
        options: Options(
          contentType: 'application/json',
          headers: {'Authorization': 'Bearer ${accessToken.trim()}'},
        ),
      );
      return true;
    } on DioException catch (e) {
      // Dropbox returns 409 when a path is not found.
      if (e.response?.statusCode == 409) {
        return false;
      }
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  void _parseListResponse(
    Map<String, dynamic> json,
    List<RemoteFileInfo> results,
  ) {
    final entries = json['entries'] as List<dynamic>? ?? [];
    for (final entry in entries) {
      final map = entry as Map<String, dynamic>;
      // Only include files, skip folders.
      if (map['.tag'] != 'file') continue;

      results.add(
        RemoteFileInfo(
          remotePath: map['path_display'] as String? ?? map['name'] as String,
          sizeBytes: map['size'] as int? ?? 0,
          modifiedAt:
              DateTime.tryParse(map['server_modified'] as String? ?? '') ??
              DateTime.now(),
        ),
      );
    }
  }
}
