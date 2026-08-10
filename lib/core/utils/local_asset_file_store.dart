import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:pass_doc_manager/core/utils/local_asset_path_resolver.dart';

class LocalAssetFileStore {
  const LocalAssetFileStore._();

  static Future<String?> copyIntoAppSupport({
    required String sourcePath,
    required String directoryName,
    required String fileNamePrefix,
  }) async {
    final normalized = LocalAssetPathResolver.normalizePath(sourcePath);
    if (normalized.isEmpty) {
      return null;
    }

    try {
      final sourceFile = File(normalized);
      if (!await sourceFile.exists()) {
        return null;
      }

      final supportDirectory = await getApplicationSupportDirectory();
      final outputDirectory = Directory(
        '${supportDirectory.path}${Platform.pathSeparator}$directoryName',
      );
      if (!await outputDirectory.exists()) {
        await outputDirectory.create(recursive: true);
      }

      final extension = _extensionFromPath(normalized);
      final stamp = DateTime.now().microsecondsSinceEpoch;
      final safePrefix = _safeFileSegment(fileNamePrefix);
      final fileName = '${safePrefix}_$stamp$extension';
      final destinationPath =
          '${outputDirectory.path}${Platform.pathSeparator}$fileName';

      if (normalized == destinationPath) {
        return normalized;
      }

      final output = await sourceFile.copy(destinationPath);
      if (!await output.exists()) {
        return null;
      }

      final sourceLength = await sourceFile.length();
      final outputLength = await output.length();
      if (sourceLength > 0 && outputLength != sourceLength) {
        try {
          await output.delete();
        } catch (_) {
          // Best effort cleanup for partial copies.
        }
        return null;
      }

      return output.path;
    } catch (_) {
      return null;
    }
  }

  static String _extensionFromPath(String path) {
    final normalized = path.trim().toLowerCase();
    final dotIndex = normalized.lastIndexOf('.');
    if (dotIndex == -1 || dotIndex == normalized.length - 1) {
      return '';
    }
    final extension = normalized.substring(dotIndex);
    return RegExp(r'^\.[a-z0-9]{1,12}$').hasMatch(extension) ? extension : '';
  }

  static String _safeFileSegment(String value) {
    final normalized = value
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
    return normalized.isEmpty ? 'asset' : normalized;
  }
}
