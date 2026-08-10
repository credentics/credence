import 'dart:typed_data';

/// Metadata about a file stored on a remote storage provider.
class RemoteFileInfo {
  const RemoteFileInfo({
    required this.remotePath,
    required this.sizeBytes,
    required this.modifiedAt,
  });

  final String remotePath;
  final int sizeBytes;
  final DateTime modifiedAt;
}

/// Abstract interface for remote storage backends used by the backup system.
///
/// Implementations handle uploading, downloading, listing, and deleting
/// individual files on a specific storage provider (e.g., Dropbox, Google
/// Drive).
abstract class RemoteStorageProvider {
  /// Uploads [bytes] to [remotePath], creating or overwriting the file.
  Future<void> uploadFile({
    required String remotePath,
    required Uint8List bytes,
  });

  /// Downloads the file at [remotePath] and returns its contents.
  Future<Uint8List> downloadFile({required String remotePath});

  /// Lists all files within [directory] on the remote storage.
  Future<List<RemoteFileInfo>> listFiles({required String directory});

  /// Deletes the file at [remotePath].
  Future<void> deleteFile({required String remotePath});

  /// Returns `true` if a file exists at [remotePath].
  Future<bool> fileExists({required String remotePath});
}
