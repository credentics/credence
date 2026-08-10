/// OAuth configuration.
///
/// All values MUST be injected at build time via `--dart-define` flags.
/// There are no hardcoded defaults — the build will still compile, but
/// features depending on these keys will be disabled at runtime when
/// the values are empty.
///
/// Example build command:
/// ```
/// flutter run \
///   --dart-define=DROPBOX_APP_KEY=your_key \
///   --dart-define=GOOGLE_DRIVE_CLIENT_ID=your_client_id
/// ```
class OAuthConfig {
  OAuthConfig._();

  /// Dropbox OAuth app key. Empty when not provided at build time.
  static const String dropboxAppKey = String.fromEnvironment(
    'DROPBOX_APP_KEY',
  );

  /// Google Drive OAuth client ID. Empty when not provided at build time.
  static const String googleDriveClientId = String.fromEnvironment(
    'GOOGLE_DRIVE_CLIENT_ID',
  );

  /// Whether Dropbox integration is available (key was provided at build).
  static bool get isDropboxConfigured => dropboxAppKey.isNotEmpty;

  /// Whether Google Drive integration is available (key was provided at build).
  static bool get isGoogleDriveConfigured => googleDriveClientId.isNotEmpty;
}
