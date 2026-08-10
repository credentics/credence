import 'dart:io';

import 'package:path_provider/path_provider.dart';

class LocalAssetPathResolver {
  const LocalAssetPathResolver._();

  static const Set<String> _portableDirectories = <String>{
    'collection_block_assets',
    'collection_icons',
    'company_logos',
    'document_images',
    'identity_documents',
    'profile_images',
    'property_document_assets',
    'reference_assets',
    'travel_trip_assets',
    'vault_mirror_restored',
    'work_company_logos',
    'work_document_assets',
    'work_statement_assets',
  };

  static String? _cachedAppSupportPath;

  static Future<void> initialize() async {
    await _ensureAppSupportPath();
  }

  static Future<String?> getAppSupportPath() async {
    await _ensureAppSupportPath();
    return _cachedAppSupportPath;
  }

  static String normalizePath(String rawPath) {
    final trimmed = rawPath.trim();
    if (trimmed.isEmpty) {
      return trimmed;
    }
    if (trimmed.startsWith('file://')) {
      try {
        return Uri.parse(trimmed).toFilePath();
      } catch (_) {
        return trimmed;
      }
    }
    return trimmed;
  }

  static bool isPortablePath(String rawPath) {
    final normalized = normalizePath(rawPath);
    if (normalized.isEmpty) {
      return false;
    }
    if (normalized.startsWith('files/')) {
      return true;
    }
    return _portableDirectories.any(
      (directory) => normalized.startsWith('$directory/'),
    );
  }

  static String toStoredPortablePath(String rawPath) {
    final normalized = normalizePath(rawPath);
    if (normalized.isEmpty || _isRemoteLikePath(normalized)) {
      return normalized;
    }
    if (isPortablePath(normalized)) {
      return normalized;
    }
    return extractPortablePath(normalized) ?? normalized;
  }

  static String? extractPortablePath(String rawPath) {
    final normalized = normalizePath(rawPath);
    if (normalized.isEmpty) {
      return null;
    }
    if (normalized.startsWith('files/')) {
      return normalized;
    }
    for (final directory in _portableDirectories) {
      final marker = '/$directory/';
      final markerIndex = normalized.lastIndexOf(marker);
      if (markerIndex == -1) {
        continue;
      }
      final suffix = normalized.substring(markerIndex + marker.length).trim();
      if (suffix.isEmpty) {
        return null;
      }
      return '$directory/$suffix';
    }
    return null;
  }

  static Future<String> resolveRuntimePath(String rawPath) async {
    await _ensureAppSupportPath();
    return resolveRuntimePathSync(rawPath);
  }

  static String resolveRuntimePathSync(String rawPath) {
    final normalized = normalizePath(rawPath);
    if (normalized.isEmpty || _isRemoteLikePath(normalized)) {
      return normalized;
    }
    if (File(normalized).existsSync()) {
      return normalized;
    }

    final appSupportPath = _cachedAppSupportPath;
    if (appSupportPath == null || appSupportPath.isEmpty) {
      return normalized;
    }

    final portable = isPortablePath(normalized)
        ? normalized
        : extractPortablePath(normalized);
    if (portable != null && portable.isNotEmpty) {
      return _portableToAbsolutePath(
        portablePath: portable,
        appSupportPath: appSupportPath,
      );
    }

    if (!_looksAbsolutePath(normalized)) {
      return _portableToAbsolutePath(
        portablePath: normalized,
        appSupportPath: appSupportPath,
      );
    }

    return normalized;
  }

  static Future<String?> resolveExistingPath(String rawPath) async {
    await _ensureAppSupportPath();
    return resolveExistingPathSync(rawPath);
  }

  static String? resolveExistingPathSync(String rawPath) {
    final resolved = resolveRuntimePathSync(rawPath);
    if (resolved.isEmpty) {
      return null;
    }
    return File(resolved).existsSync() ? resolved : null;
  }

  static String portableFileName(String rawPath) {
    final normalized = normalizePath(rawPath);
    if (normalized.isEmpty) {
      return '';
    }
    final separators = normalized.split(RegExp(r'[\\/]'));
    return separators.isEmpty ? normalized : separators.last;
  }

  static Future<void> _ensureAppSupportPath() async {
    if (_cachedAppSupportPath != null) {
      return;
    }
    try {
      final directory = await getApplicationSupportDirectory();
      _cachedAppSupportPath = directory.path;
    } catch (_) {
      _cachedAppSupportPath = null;
    }
  }

  static bool _isRemoteLikePath(String value) {
    final uri = Uri.tryParse(value);
    if (uri == null || !uri.hasScheme) {
      return false;
    }
    final scheme = uri.scheme.toLowerCase();
    return scheme == 'http' ||
        scheme == 'https' ||
        scheme == 'data' ||
        scheme == 'blob';
  }

  static bool _looksAbsolutePath(String value) {
    return value.startsWith('/') ||
        value.startsWith(r'\\') ||
        RegExp(r'^[A-Za-z]:[\\/]').hasMatch(value);
  }

  static String _portableToAbsolutePath({
    required String portablePath,
    required String appSupportPath,
  }) {
    if (portablePath.startsWith('files/')) {
      final suffix = portablePath.substring('files/'.length);
      return '$appSupportPath${Platform.pathSeparator}document_images${Platform.pathSeparator}${suffix.replaceAll('/', Platform.pathSeparator)}';
    }
    return '$appSupportPath${Platform.pathSeparator}${portablePath.replaceAll('/', Platform.pathSeparator)}';
  }
}
