import 'package:flutter_test/flutter_test.dart';
import 'package:pass_doc_manager/data/vault_sync/datasources/local/vault_sync_prefs_local_data_source.dart';
import 'package:pass_doc_manager/data/vault_sync/dtos/vault_sync_manifest_dto.dart';
import 'package:pass_doc_manager/data/vault_sync/dtos/vault_sync_prefs_dto.dart';
import 'package:pass_doc_manager/data/vault_sync/services/dropbox_token_refresh_service.dart';
import 'package:pass_doc_manager/features/backup/infrastructure/services/dropbox_auth_service.dart';

void main() {
  group('DropboxTokenRefreshService', () {
    test('refreshes and stores a new access token when missing', () async {
      final now = DateTime.utc(2026, 5, 22, 10);
      final initial = const VaultSyncPrefsDto.defaults().copyWith(
        dropboxAccessToken: '',
        dropboxRefreshToken: 'refresh-token',
        dropboxAccessTokenExpiresAtIso: '',
      );
      final prefsStore = _FakeVaultSyncPrefsLocalDataSource(initial);
      final service = DropboxTokenRefreshService(
        prefsLocalDataSource: prefsStore,
        now: () => now,
        refreshAccessToken: (refreshToken) async {
          expect(refreshToken, 'refresh-token');
          return const DropboxTokenResult(
            accessToken: 'fresh-access-token',
            expiresIn: 3600,
          );
        },
      );

      final refreshed = await service.refreshIfNeeded(initial);

      expect(refreshed.dropboxAccessToken, 'fresh-access-token');
      expect(refreshed.dropboxRefreshToken, 'refresh-token');
      expect(
        refreshed.dropboxAccessTokenExpiresAtIso,
        DateTime.utc(2026, 5, 22, 11).toIso8601String(),
      );
      expect(prefsStore.lastWritten?.dropboxAccessToken, 'fresh-access-token');
    });

    test('keeps the current token when it is not close to expiry', () async {
      final now = DateTime.utc(2026, 5, 22, 10);
      var refreshCalled = false;
      final initial = const VaultSyncPrefsDto.defaults().copyWith(
        dropboxAccessToken: 'current-access-token',
        dropboxRefreshToken: 'refresh-token',
        dropboxAccessTokenExpiresAtIso: DateTime.utc(
          2026,
          5,
          22,
          10,
          10,
        ).toIso8601String(),
      );
      final prefsStore = _FakeVaultSyncPrefsLocalDataSource(initial);
      final service = DropboxTokenRefreshService(
        prefsLocalDataSource: prefsStore,
        now: () => now,
        refreshAccessToken: (_) async {
          refreshCalled = true;
          return const DropboxTokenResult(accessToken: 'unexpected');
        },
      );

      final refreshed = await service.refreshIfNeeded(initial);

      expect(refreshed.dropboxAccessToken, 'current-access-token');
      expect(refreshCalled, isFalse);
      expect(prefsStore.lastWritten, isNull);
    });
  });

  test('VaultSyncPrefsDto reads legacy prefs without refresh fields', () {
    final prefs = VaultSyncPrefsDto.fromMap(const {
      'targetType': 'dropbox_cloud',
      'localFolderPath': '',
      'dropboxAccessToken': 'legacy-token',
    });

    expect(prefs.dropboxAccessToken, 'legacy-token');
    expect(prefs.dropboxRefreshToken, isEmpty);
    expect(prefs.dropboxAccessTokenExpiresAtIso, isEmpty);
  });
}

class _FakeVaultSyncPrefsLocalDataSource
    implements VaultSyncPrefsLocalDataSource {
  _FakeVaultSyncPrefsLocalDataSource(this._prefs);

  VaultSyncPrefsDto _prefs;
  VaultSyncPrefsDto? lastWritten;

  @override
  Future<VaultSyncPrefsDto> readPrefs() async => _prefs;

  @override
  Future<void> writePrefs(VaultSyncPrefsDto prefs) async {
    _prefs = prefs;
    lastWritten = prefs;
  }

  @override
  Future<void> storeConflictSnapshot({
    required VaultSyncManifestDto manifest,
    required List<int> encryptedPayload,
  }) async {}
}
