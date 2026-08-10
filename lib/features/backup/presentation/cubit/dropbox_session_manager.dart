import 'package:dio/dio.dart';
import 'package:pass_doc_manager/app/di/injection.dart';
import 'package:pass_doc_manager/data/vault_sync/datasources/local/vault_sync_prefs_local_data_source.dart';

/// Encapsulates Dropbox session concerns that used to live inline in
/// `BackupCubit`: detecting an expired-session error and clearing the stored
/// Dropbox tokens. It deliberately holds no cubit state — the cubit still owns
/// emitting `dropboxSessionExpired` — so it stays independently testable.
class DropboxSessionManager {
  DropboxSessionManager({VaultSyncPrefsLocalDataSource? prefs}) : _prefs = prefs;

  VaultSyncPrefsLocalDataSource? _prefs;
  VaultSyncPrefsLocalDataSource get _store =>
      _prefs ??= getIt<VaultSyncPrefsLocalDataSource>();

  /// Whether [error] indicates a Dropbox 401 / expired-session failure.
  static bool isAuthError(Object error) {
    if (error is DioException && error.response?.statusCode == 401) {
      return true;
    }
    final msg = error.toString().toLowerCase();
    return msg.contains('401') ||
        msg.contains('unauthorized') ||
        msg.contains('expired_access_token') ||
        msg.contains('invalid_access_token') ||
        msg.contains('invalid_token');
  }

  /// Clears the stored Dropbox tokens. Returns `true` if a session actually
  /// existed (so the caller can decide whether to surface a "session expired"
  /// state). Never throws.
  Future<bool> expireSession() async {
    try {
      final prefs = await _store.readPrefs();
      final hadSession =
          prefs.dropboxAccessToken.trim().isNotEmpty ||
          prefs.dropboxRefreshToken.trim().isNotEmpty;
      await _store.writePrefs(
        prefs.copyWith(
          dropboxAccessToken: '',
          dropboxRefreshToken: '',
          dropboxAccessTokenExpiresAtIso: '',
        ),
      );
      return hadSession;
    } catch (_) {
      return false;
    }
  }
}
