import 'package:dio/dio.dart';

class LinkPreviewData {
  const LinkPreviewData({
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.domain,
  });

  final String title;
  final String description;
  final String? imageUrl;
  final String domain;
}

class LinkPreviewService {
  LinkPreviewService({Dio? dio}) : _dio = dio ?? Dio();

  final Dio _dio;

  Future<LinkPreviewData?> fetch(String url) async {
    final cleaned = url.trim();
    if (cleaned.isEmpty) return null;

    final uri = Uri.tryParse(cleaned);
    if (uri == null || !uri.hasScheme) return null;

    try {
      final response = await _dio.get<String>(
        cleaned,
        options: Options(
          headers: const <String, String>{
            'User-Agent': 'Credence/1.0 (link-preview)',
          },
          responseType: ResponseType.plain,
          sendTimeout: const Duration(seconds: 6),
          receiveTimeout: const Duration(seconds: 6),
          followRedirects: true,
          maxRedirects: 3,
        ),
      );

      final html = response.data ?? '';
      if (html.isEmpty) return null;

      final title = _extractMeta(html, 'og:title') ??
          _extractMeta(html, 'twitter:title') ??
          _extractHtmlTitle(html) ??
          '';
      final description = _extractMeta(html, 'og:description') ??
          _extractMeta(html, 'twitter:description') ??
          _extractMeta(html, 'description') ??
          '';
      final imageUrl = _extractMeta(html, 'og:image') ??
          _extractMeta(html, 'twitter:image');

      final domain = uri.host.startsWith('www.')
          ? uri.host.substring(4)
          : uri.host;

      return LinkPreviewData(
        title: title,
        description: description,
        imageUrl: _resolveImageUrl(imageUrl, uri),
        domain: domain,
      );
    } catch (_) {
      return null;
    }
  }

  String? _extractMeta(String html, String property) {
    // Match both property="..." and name="..." attributes
    final patterns = [
      RegExp(
        '<meta[^>]*property=["\']$property["\'][^>]*content=["\']([^"\']*)["\']',
        caseSensitive: false,
      ),
      RegExp(
        '<meta[^>]*content=["\']([^"\']*)["\'][^>]*property=["\']$property["\']',
        caseSensitive: false,
      ),
      RegExp(
        '<meta[^>]*name=["\']$property["\'][^>]*content=["\']([^"\']*)["\']',
        caseSensitive: false,
      ),
      RegExp(
        '<meta[^>]*content=["\']([^"\']*)["\'][^>]*name=["\']$property["\']',
        caseSensitive: false,
      ),
    ];
    for (final pattern in patterns) {
      final match = pattern.firstMatch(html);
      if (match != null) {
        final value = match.group(1)?.trim() ?? '';
        if (value.isNotEmpty) return value;
      }
    }
    return null;
  }

  String? _extractHtmlTitle(String html) {
    final match = RegExp(
      r'<title[^>]*>(.*?)</title>',
      caseSensitive: false,
      dotAll: true,
    ).firstMatch(html);
    return match?.group(1)?.trim();
  }

  String? _resolveImageUrl(String? imageUrl, Uri pageUri) {
    if (imageUrl == null || imageUrl.trim().isEmpty) return null;
    final trimmed = imageUrl.trim();
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return trimmed;
    }
    if (trimmed.startsWith('//')) {
      return '${pageUri.scheme}:$trimmed';
    }
    return '${pageUri.scheme}://${pageUri.host}$trimmed';
  }
}
