import 'dart:typed_data';

import 'package:archive/archive.dart';

class BackupArchiveService {
  /// Creates a ZIP archive from a map of `{relativePath: bytes}`.
  ///
  /// Each entry in [files] becomes a file inside the archive at the given
  /// relative path.
  Uint8List createArchive(Map<String, Uint8List> files) {
    final archive = Archive();

    for (final entry in files.entries) {
      final file = ArchiveFile(entry.key, entry.value.length, entry.value);
      archive.addFile(file);
    }

    final encoded = ZipEncoder().encode(archive);
    return Uint8List.fromList(encoded);
  }

  /// Extracts a ZIP archive from [archiveBytes] into a map of
  /// `{relativePath: bytes}`.
  ///
  /// Only files (not directories) are included in the result.
  Map<String, Uint8List> extractArchive(Uint8List archiveBytes) {
    final archive = ZipDecoder().decodeBytes(archiveBytes);
    final result = <String, Uint8List>{};

    for (final file in archive) {
      if (file.isFile) {
        result[file.name] = Uint8List.fromList(file.content as List<int>);
      }
    }

    return result;
  }
}
