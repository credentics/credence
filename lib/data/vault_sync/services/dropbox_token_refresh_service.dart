import 'package:pass_doc_manager/data/vault_sync/datasources/local/vault_sync_prefs_local_data_source.dart';
import 'package:pass_doc_manager/data/vault_sync/dtos/vault_sync_prefs_dto.dart';
import 'package:pass_doc_manager/features/backup/infrastructure/services/dropbox_auth_service.dart';

typedef DropboxAccessTokenRefresh =
    Future<DropboxTokenResult?> Function(String refreshToken);

class DropboxTokenRefreshService {
  DropboxTokenRefreshService({
    required this.prefsLocalDataSource,
    DropboxAccessTokenRefresh? refreshAccessToken,
    DateTime Function()? now,
    this.refreshWindow = const Duration(minutes: 5),
  }) : _refreshAccessToken =
           refreshAccessToken ?? DropboxAuthService().refreshAccessToken,
       _now = now ?? DateTime.now;

  final VaultSyncPrefsLocalDataSource prefsLocalDataSource;
  final DropboxAccessTokenRefresh _refreshAccessToken;
  final DateTime Function() _now;
  final Duration refreshWindow;

  Future<VaultSyncPrefsDto> refreshIfNeeded(VaultSyncPrefsDto prefs) async {
    final refreshToken = prefs.dropboxRefreshToken.trim();
    if (refreshToken.isEmpty || !_shouldRefresh(prefs)) {
      return prefs;
    }

    final result = await _refreshAccessToken(refreshToken);
    if (result == null || !result.isValid) {
      return prefs;
    }

    final next = prefs.copyWith(
      dropboxAccessToken: result.accessToken.trim(),
      dropboxRefreshToken: (result.refreshToken ?? refreshToken).trim(),
      dropboxAccessTokenExpiresAtIso: result.accessTokenExpiresAtIso(
        now: _now(),
      ),
    );
    await prefsLocalDataSource.writePrefs(next);
    return next;
  }

  bool _shouldRefresh(VaultSyncPrefsDto prefs) {
    if (prefs.dropboxAccessToken.trim().isEmpty) {
      return true;
    }

    final expiresAt = DateTime.tryParse(
      prefs.dropboxAccessTokenExpiresAtIso.trim(),
    );
    if (expiresAt == null) {
      return true;
    }

    return _now().toUtc().add(refreshWindow).isAfter(expiresAt.toUtc());
  }
}
