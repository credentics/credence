import 'package:pass_doc_manager/data/vault_sync/datasources/local/vault_sync_prefs_local_data_source.dart';
import 'package:pass_doc_manager/data/vault_sync/dtos/vault_sync_prefs_dto.dart';
import 'package:pass_doc_manager/data/vault_sync/services/dropbox_token_refresh_service.dart';
import 'package:pass_doc_manager/features/backup/domain/entities/cloud_provider_type.dart';

/// Pure provider-routing logic extracted from `BackupCubit`: which cloud
/// provider is active, its access token, its sync target value, the mirror
/// directory, and refreshing an expiring token. Holds no cubit state, so it is
/// independently unit-testable.
class CloudSyncService {
  const CloudSyncService();

  /// The provider the user selected, defaulting to Dropbox.
  CloudProviderType activeProvider(VaultSyncPrefsDto prefs) =>
      CloudProviderTypeX.fromKey(prefs.selectedCloudProvider) ??
      CloudProviderType.dropbox;

  /// Refreshes the Dropbox token when close to expiry; other providers are
  /// returned unchanged.
  Future<VaultSyncPrefsDto> refreshTokenIfNeeded(
    VaultSyncPrefsLocalDataSource syncPrefs,
    VaultSyncPrefsDto prefs,
    CloudProviderType provider,
  ) {
    if (provider != CloudProviderType.dropbox) {
      return Future.value(prefs);
    }
    return DropboxTokenRefreshService(
      prefsLocalDataSource: syncPrefs,
    ).refreshIfNeeded(prefs);
  }

  /// The provider's current access token (empty for iCloud).
  String token(VaultSyncPrefsDto prefs, CloudProviderType provider) {
    return switch (provider) {
      CloudProviderType.dropbox => prefs.dropboxAccessToken.trim(),
      CloudProviderType.googleDrive => prefs.googleDriveAccessToken.trim(),
      CloudProviderType.iCloud => '',
    };
  }

  /// The persisted sync-target key for the provider.
  String targetValue(CloudProviderType provider) {
    return switch (provider) {
      CloudProviderType.dropbox => 'dropbox_cloud',
      CloudProviderType.googleDrive => 'google_drive_cloud',
      CloudProviderType.iCloud => 'none',
    };
  }

  /// The remote mirror directory, defaulting to `/Credence`.
  String mirrorDirectory(VaultSyncPrefsDto prefs) {
    final raw = prefs.dropboxDirectoryPath.trim();
    if (raw.isEmpty) {
      return '/Credence';
    }
    return raw.startsWith('/') ? raw : '/$raw';
  }
}
