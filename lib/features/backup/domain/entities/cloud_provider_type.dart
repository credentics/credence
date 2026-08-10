/// Enumerates the cloud storage providers supported by the backup system.
enum CloudProviderType {
  dropbox,
  googleDrive,
  iCloud,
}

/// Convenience helpers for [CloudProviderType].
extension CloudProviderTypeX on CloudProviderType {
  /// Stable key used for persistence (e.g. shared prefs, JSON).
  String get key => switch (this) {
        CloudProviderType.dropbox => 'dropbox',
        CloudProviderType.googleDrive => 'google_drive',
        CloudProviderType.iCloud => 'icloud',
      };

  /// Human-readable label for the UI.
  String get label => switch (this) {
        CloudProviderType.dropbox => 'Dropbox',
        CloudProviderType.googleDrive => 'Google Drive',
        CloudProviderType.iCloud => 'iCloud',
      };

  /// Material icon name hint for the UI.
  String get iconDescription => switch (this) {
        CloudProviderType.dropbox => 'cloud_done',
        CloudProviderType.googleDrive => 'add_to_drive',
        CloudProviderType.iCloud => 'cloud',
      };

  /// Parses a persisted key back into an enum value.
  static CloudProviderType? fromKey(String key) {
    for (final type in CloudProviderType.values) {
      if (type.key == key) return type;
    }
    return null;
  }
}
