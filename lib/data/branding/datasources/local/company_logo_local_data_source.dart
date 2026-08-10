import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';

class CompanyLogoLocalDataSource {
  const CompanyLogoLocalDataSource({required this.dio});

  final Dio dio;

  Future<String?> downloadLogoToLocal({
    required String iconUrl,
    required String domain,
  }) async {
    final normalizedUrl = _normalizeUrl(iconUrl);
    if (normalizedUrl.isEmpty) {
      return null;
    }

    final uri = Uri.tryParse(normalizedUrl);
    if (uri == null) {
      return null;
    }

    final response = await dio.get<List<int>>(
      uri.toString(),
      options: Options(responseType: ResponseType.bytes),
    );

    final statusCode = response.statusCode ?? 0;
    if (statusCode < 200 || statusCode >= 300) {
      return null;
    }

    final bytes = response.data;
    if (bytes == null || bytes.isEmpty) {
      return null;
    }

    if (!_looksLikeImage(response: response, bytes: bytes)) {
      return null;
    }

    final root = await getApplicationSupportDirectory();
    final logosDir = Directory('${root.path}/company_logos');
    if (!logosDir.existsSync()) {
      await logosDir.create(recursive: true);
    }

    final ext = _resolveExtension(
      path: uri.path,
      contentType: response.headers.value(Headers.contentTypeHeader),
      bytes: bytes,
    );
    final safeDomain = domain.trim().toLowerCase().replaceAll(
      RegExp(r'[^a-z0-9._-]'),
      '_',
    );
    final normalizedDomain = safeDomain.isEmpty ? 'brand' : safeDomain;
    final file = File('${logosDir.path}/${normalizedDomain}_logo.$ext');
    await file.writeAsBytes(bytes, flush: true);
    return file.path;
  }

  String _resolveExtension({
    required String path,
    required String? contentType,
    required List<int> bytes,
  }) {
    final normalizedType = (contentType ?? '').toLowerCase();
    if (normalizedType.contains('image/svg')) {
      return 'svg';
    }
    if (normalizedType.contains('image/png')) {
      return 'png';
    }
    if (normalizedType.contains('image/jpeg') ||
        normalizedType.contains('image/jpg')) {
      return 'jpg';
    }
    if (normalizedType.contains('image/webp')) {
      return 'webp';
    }
    if (normalizedType.contains('image/gif')) {
      return 'gif';
    }

    if (_looksLikeSvgBytes(bytes)) {
      return 'svg';
    }
    if (_looksLikePng(bytes)) {
      return 'png';
    }
    if (_looksLikeJpeg(bytes)) {
      return 'jpg';
    }
    if (_looksLikeWebp(bytes)) {
      return 'webp';
    }

    final dot = path.lastIndexOf('.');
    if (dot == -1 || dot == path.length - 1) {
      return 'img';
    }
    final ext = path.substring(dot + 1).toLowerCase();
    if (!RegExp(r'^[a-z0-9]{2,5}$').hasMatch(ext)) {
      return 'img';
    }
    return ext;
  }

  bool _looksLikeImage({
    required Response<List<int>> response,
    required List<int> bytes,
  }) {
    final type = (response.headers.value(Headers.contentTypeHeader) ?? '')
        .toLowerCase();
    if (type.startsWith('image/')) {
      return true;
    }

    if (_looksLikeSvgBytes(bytes) ||
        _looksLikePng(bytes) ||
        _looksLikeJpeg(bytes) ||
        _looksLikeWebp(bytes)) {
      return true;
    }

    return false;
  }

  bool _looksLikeSvgBytes(List<int> bytes) {
    final peek = Uint8List.fromList(bytes.take(300).toList(growable: false));
    final head = String.fromCharCodes(peek).toLowerCase();
    return head.contains('<svg') || head.contains('<?xml');
  }

  bool _looksLikePng(List<int> bytes) {
    if (bytes.length < 8) {
      return false;
    }
    const pngHeader = [0x89, 0x50, 0x4E, 0x47];
    for (var i = 0; i < pngHeader.length; i++) {
      if (bytes[i] != pngHeader[i]) {
        return false;
      }
    }
    return true;
  }

  bool _looksLikeJpeg(List<int> bytes) {
    if (bytes.length < 3) {
      return false;
    }
    return bytes[0] == 0xFF && bytes[1] == 0xD8 && bytes[2] == 0xFF;
  }

  bool _looksLikeWebp(List<int> bytes) {
    if (bytes.length < 12) {
      return false;
    }
    final riff = String.fromCharCodes(bytes.take(4));
    final webp = String.fromCharCodes(bytes.skip(8).take(4));
    return riff == 'RIFF' && webp == 'WEBP';
  }

  String _normalizeUrl(String raw) {
    final value = raw.trim();
    if (value.isEmpty) {
      return '';
    }
    if (value.startsWith('//')) {
      return 'https:$value';
    }
    return value;
  }
}
