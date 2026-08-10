/// Handles iCloud authentication and availability checks.
///
/// iCloud authentication is handled by the OS automatically.
/// The user must be signed into iCloud on their device.
/// No OAuth flow is needed — just check if iCloud is available.
///
/// For now, this is a stub. Native implementation requires:
/// 1. Add CloudKit entitlements to iOS/macOS runner
/// 2. Create a CloudKit container in Apple Developer portal
/// 3. Use platform channels to check iCloud availability via
///    CKContainer.default().accountStatus on iOS/macOS
class ICloudAuthService {
  /// Checks whether iCloud is available on the current device.
  ///
  /// Returns `true` if the user is signed into iCloud and the app
  /// has the necessary entitlements. Returns `false` otherwise.
  ///
  /// TODO: Implement via platform channel.
  /// On iOS/macOS: check CKContainer.default().accountStatus
  /// On other platforms: always returns false.
  Future<bool> isICloudAvailable() async {
    // Stub — native implementation pending.
    return false;
  }

  /// Human-readable status message explaining the current iCloud state.
  String get statusMessage =>
      'iCloud backup requires iOS/macOS with iCloud enabled. '
      'Coming in a future update.';
}
