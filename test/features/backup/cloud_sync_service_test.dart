import 'package:flutter_test/flutter_test.dart';
import 'package:pass_doc_manager/data/vault_sync/datasources/local/vault_sync_prefs_local_data_source.dart';
import 'package:pass_doc_manager/data/vault_sync/dtos/vault_sync_prefs_dto.dart';
import 'package:pass_doc_manager/features/backup/domain/entities/cloud_provider_type.dart';
import 'package:pass_doc_manager/features/backup/presentation/cubit/cloud_sync_service.dart';

void main() {
  const service = CloudSyncService();
  const base = VaultSyncPrefsDto.defaults();

  group('CloudSyncService.activeProvider', () {
    test('defaults to Dropbox for empty/unknown key', () {
      expect(
        service.activeProvider(base.copyWith(selectedCloudProvider: '')),
        CloudProviderType.dropbox,
      );
      expect(
        service.activeProvider(base.copyWith(selectedCloudProvider: 'wat')),
        CloudProviderType.dropbox,
      );
    });

    test('resolves the selected provider key', () {
      expect(
        service.activeProvider(
          base.copyWith(selectedCloudProvider: 'google_drive'),
        ),
        CloudProviderType.googleDrive,
      );
    });
  });

  group('CloudSyncService.token / targetValue', () {
    final prefs = base.copyWith(
      dropboxAccessToken: '  dbx  ',
      googleDriveAccessToken: 'gdrive',
    );

    test('returns the trimmed token per provider', () {
      expect(service.token(prefs, CloudProviderType.dropbox), 'dbx');
      expect(service.token(prefs, CloudProviderType.googleDrive), 'gdrive');
      expect(service.token(prefs, CloudProviderType.iCloud), '');
    });

    test('maps provider to its target key', () {
      expect(service.targetValue(CloudProviderType.dropbox), 'dropbox_cloud');
      expect(
        service.targetValue(CloudProviderType.googleDrive),
        'google_drive_cloud',
      );
      expect(service.targetValue(CloudProviderType.iCloud), 'none');
    });
  });

  group('CloudSyncService.mirrorDirectory', () {
    test('defaults an empty path to /Credence', () {
      expect(
        service.mirrorDirectory(base.copyWith(dropboxDirectoryPath: '')),
        '/Credence',
      );
    });

    test('prefixes a leading slash and preserves absolute paths', () {
      expect(
        service.mirrorDirectory(base.copyWith(dropboxDirectoryPath: 'Docs')),
        '/Docs',
      );
      expect(
        service.mirrorDirectory(
          base.copyWith(dropboxDirectoryPath: '/My/Vault'),
        ),
        '/My/Vault',
      );
    });
  });

  group('CloudSyncService.refreshTokenIfNeeded', () {
    test('returns prefs unchanged for non-Dropbox providers', () async {
      final result = await service.refreshTokenIfNeeded(
        _ThrowingPrefs(),
        base,
        CloudProviderType.googleDrive,
      );
      expect(result, same(base));
    });
  });
}

/// Proves the non-Dropbox path never touches the data source (any call throws).
class _ThrowingPrefs implements VaultSyncPrefsLocalDataSource {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw StateError('data source must not be used for non-Dropbox');
}
