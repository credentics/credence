import 'dart:typed_data';

import 'package:pass_doc_manager/features/backup/infrastructure/providers/remote_storage_provider.dart';

/// Stub implementation of [RemoteStorageProvider] for iCloud.
///
/// iCloud integration requires native platform code (CloudKit on iOS/macOS,
/// platform channels, and appropriate entitlements). This stub satisfies the
/// interface so the rest of the architecture can reference it, but every method
/// throws [UnimplementedError] until the native layer is implemented.
class ICloudBackupProvider implements RemoteStorageProvider {
  const ICloudBackupProvider();

  static const String _message =
      'iCloud backup requires native iOS/macOS implementation. '
      'Add CloudKit entitlements and implement via platform channels.';

  @override
  Future<void> uploadFile({
    required String remotePath,
    required Uint8List bytes,
  }) {
    throw UnimplementedError(_message);
  }

  @override
  Future<Uint8List> downloadFile({required String remotePath}) {
    throw UnimplementedError(_message);
  }

  @override
  Future<List<RemoteFileInfo>> listFiles({required String directory}) {
    throw UnimplementedError(_message);
  }

  @override
  Future<void> deleteFile({required String remotePath}) {
    throw UnimplementedError(_message);
  }

  @override
  Future<bool> fileExists({required String remotePath}) {
    throw UnimplementedError(_message);
  }
}
