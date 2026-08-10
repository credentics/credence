import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:dio/dio.dart';

abstract class VaultMirrorImportSource {
  String get label;

  Future<String> readText(String relativePath);

  Stream<List<int>> openRead(String relativePath);
}


/// Reads a mirror straight out of an in-memory [Archive] — a
/// `Credence-Vault-*.zip` export. This lets a `.zip` restore through the exact
/// same [VaultMirrorImportService] path as the cloud mirror, with no temp
/// unpacking: manifest, snapshot, and every asset are pulled from the archive
/// entry whose name matches the mirror-relative path.
class ZipArchiveVaultMirrorImportSource implements VaultMirrorImportSource {
  const ZipArchiveVaultMirrorImportSource(this.archive);

  final Archive archive;

  @override
  String get label => 'vault archive';

  @override
  Future<String> readText(String relativePath) async =>
      utf8.decode(_entryBytes(relativePath));

  @override
  Stream<List<int>> openRead(String relativePath) =>
      Stream<List<int>>.value(_entryBytes(relativePath));

  List<int> _entryBytes(String relativePath) {
    final name = relativePath.trim().replaceAll('\\', '/');
    final entry = archive.findFile(name);
    if (entry == null) {
      throw StateError('Vault archive is missing "$relativePath".');
    }
    return entry.content as List<int>;
  }
}

class LocalFolderVaultMirrorImportSource implements VaultMirrorImportSource {
  const LocalFolderVaultMirrorImportSource({required this.folderPath});

  final String folderPath;

  @override
  String get label => folderPath;

  @override
  Future<String> readText(String relativePath) {
    return File(_resolve(relativePath)).readAsString();
  }

  @override
  Stream<List<int>> openRead(String relativePath) {
    return File(_resolve(relativePath)).openRead();
  }

  String _resolve(String relativePath) {
    final root = Directory(folderPath.trim()).absolute.uri;
    final encoded = relativePath
        .trim()
        .replaceAll('\\', '/')
        .split('/')
        .where((part) => part.isNotEmpty && part != '.' && part != '..')
        .map(Uri.encodeComponent)
        .join('/');
    final outputUri = root.resolve(encoded).normalizePath();
    final output = outputUri.toFilePath();
    final rootPath = root.normalizePath().toFilePath();
    if (!output.startsWith(rootPath)) {
      throw StateError('Unsafe mirror path: $relativePath');
    }
    return output;
  }
}

class DropboxVaultMirrorImportSource implements VaultMirrorImportSource {
  const DropboxVaultMirrorImportSource({
    required this.dio,
    required this.accessToken,
    required this.directoryPath,
  });

  final Dio dio;
  final String accessToken;
  final String directoryPath;

  @override
  String get label => _normalizeRoot(directoryPath);

  @override
  Future<String> readText(String relativePath) async {
    final chunks = <int>[];
    await for (final chunk in openRead(relativePath)) {
      chunks.addAll(chunk);
    }
    return utf8.decode(chunks);
  }

  @override
  Stream<List<int>> openRead(String relativePath) async* {
    late final Response<ResponseBody> response;
    try {
      response = await dio.post<ResponseBody>(
        'https://content.dropboxapi.com/2/files/download',
        options: Options(
          responseType: ResponseType.stream,
          headers: {
            'Authorization': 'Bearer ${accessToken.trim()}',
            'Dropbox-API-Arg': _dropboxApiArg({
              'path': _remotePath(_normalizeRoot(directoryPath), relativePath),
            }),
          },
        ),
      );
    } on DioException catch (error) {
      throw StateError(
        'Dropbox could not download $relativePath: ${_dropboxErrorSummary(error)}',
      );
    }

    final body = response.data;
    if (body == null) {
      throw StateError('Dropbox returned an empty response for $relativePath.');
    }
    yield* body.stream;
  }

  String _normalizeRoot(String value) {
    final trimmed = value.trim().isEmpty ? '/Credence' : value.trim();
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

  String _dropboxErrorSummary(DioException error) {
    final status = error.response?.statusCode;
    final data = error.response?.data;
    final body = data is List<int>
        ? utf8.decode(data, allowMalformed: true).trim()
        : '${data ?? error.message ?? error}'.trim();
    return status == null ? body : 'HTTP $status $body';
  }
}

class GoogleDriveVaultMirrorImportSource implements VaultMirrorImportSource {
  const GoogleDriveVaultMirrorImportSource({
    required this.dio,
    required this.accessToken,
    required this.directoryPath,
  });

  final Dio dio;
  final String accessToken;
  final String directoryPath;

  static const String _driveApiBase = 'https://www.googleapis.com/drive/v3';

  @override
  String get label => _normalizeRootLabel(directoryPath);

  @override
  Future<String> readText(String relativePath) async {
    final chunks = <int>[];
    await for (final chunk in openRead(relativePath)) {
      chunks.addAll(chunk);
    }
    return utf8.decode(chunks);
  }

  @override
  Stream<List<int>> openRead(String relativePath) async* {
    final rootId = await _findFolderIdByRootPath();
    if (rootId == null) {
      throw StateError('Google Drive mirror root was not found.');
    }
    final fileId = await _findFileIdByPath(
      rootId: rootId,
      relativePath: relativePath,
    );
    if (fileId == null) {
      throw StateError('Google Drive file not found: $relativePath.');
    }

    late final Response<ResponseBody> response;
    try {
      response = await dio.get<ResponseBody>(
        '$_driveApiBase/files/$fileId',
        queryParameters: {'alt': 'media'},
        options: Options(
          responseType: ResponseType.stream,
          headers: _authHeader,
        ),
      );
    } on DioException catch (error) {
      throw StateError(
        'Google Drive could not download $relativePath: ${_driveErrorSummary(error)}',
      );
    }

    final body = response.data;
    if (body == null) {
      throw StateError(
        'Google Drive returned an empty response for $relativePath.',
      );
    }
    yield* body.stream;
  }

  Future<String?> _findFolderIdByRootPath() async {
    var parentId = 'root';
    for (final segment in _pathSegments(directoryPath, defaultRoot: true)) {
      final next = await _findChildIdByName(
        name: segment,
        parentFolderId: parentId,
        foldersOnly: true,
      );
      if (next == null) {
        return null;
      }
      parentId = next;
    }
    return parentId;
  }

  Future<String?> _findFileIdByPath({
    required String rootId,
    required String relativePath,
  }) async {
    final parentPath = _parentPath(relativePath);
    var parentId = rootId;
    for (final segment in _pathSegments(parentPath)) {
      final next = await _findChildIdByName(
        name: segment,
        parentFolderId: parentId,
        foldersOnly: true,
      );
      if (next == null) {
        return null;
      }
      parentId = next;
    }
    return _findChildIdByName(
      name: _fileName(relativePath),
      parentFolderId: parentId,
      foldersOnly: false,
    );
  }

  Future<String?> _findChildIdByName({
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
      options: Options(headers: _authHeader),
    );
    final files = (response.data?['files'] as List<dynamic>?) ?? [];
    if (files.isEmpty) {
      return null;
    }
    return (files.first as Map<String, dynamic>)['id'] as String?;
  }

  Map<String, String> get _authHeader => {
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

  String _normalizeRootLabel(String directoryPath) {
    final parts = _pathSegments(directoryPath, defaultRoot: true);
    return '/${parts.join('/')}';
  }

  String _escapeDriveQueryValue(String value) {
    return value.replaceAll('\\', '\\\\').replaceAll("'", r"\'");
  }

  String _driveErrorSummary(DioException error) {
    final status = error.response?.statusCode;
    final data = error.response?.data;
    final body = data is List<int>
        ? utf8.decode(data, allowMalformed: true).trim()
        : '${data ?? error.message ?? error}'.trim();
    return status == null ? body : 'HTTP $status $body';
  }
}
