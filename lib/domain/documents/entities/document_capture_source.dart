enum DocumentCaptureSource { camera, gallery }

extension DocumentCaptureSourceX on DocumentCaptureSource {
  String get key {
    return switch (this) {
      DocumentCaptureSource.camera => 'camera',
      DocumentCaptureSource.gallery => 'gallery',
    };
  }
}
