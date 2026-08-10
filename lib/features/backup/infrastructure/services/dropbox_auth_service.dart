import 'dart:convert';
import 'dart:math';

import 'package:cryptography/cryptography.dart' as crypto;
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:pass_doc_manager/app/config/oauth_config.dart';
import 'package:url_launcher/url_launcher.dart';

/// Handles Dropbox OAuth 2.0 authorization code flow with PKCE.
///
/// Flow:
/// 1. Generate code verifier, persist it to secure storage
/// 2. Open browser to Dropbox authorization URL
/// 3. User approves → Dropbox shows an authorization code on screen
/// 4. User pastes the code back in the app
/// 5. App exchanges code for short-lived access token and refresh token
class DropboxAuthService {
  DropboxAuthService({Dio? dio}) : _dio = dio ?? Dio();

  final Dio _dio;

  static String get appKey => OAuthConfig.dropboxAppKey;
  static const String _verifierStorageKey = 'dropbox_pkce_code_verifier';

  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  /// Opens the Dropbox authorization page in the browser.
  Future<void> startAuthorization() async {
    final codeVerifier = _generateCodeVerifier();

    // Persist verifier so it survives app restart
    await _secureStorage.write(key: _verifierStorageKey, value: codeVerifier);

    // PKCE S256: code_challenge = base64url(sha256(code_verifier))
    final codeChallenge = await _sha256Challenge(codeVerifier);

    final authUrl = Uri.https('www.dropbox.com', '/oauth2/authorize', {
      'client_id': appKey,
      'response_type': 'code',
      'token_access_type': 'offline',
      'code_challenge': codeChallenge,
      'code_challenge_method': 'S256',
    });

    debugPrint('[DropboxAuth] Opening authorization URL');
    await launchUrl(authUrl, mode: LaunchMode.externalApplication);
  }

  /// Exchanges the authorization code for an access token.
  Future<DropboxTokenResult?> exchangeCode(String authorizationCode) async {
    final codeVerifier = await _secureStorage.read(key: _verifierStorageKey);
    if (codeVerifier == null || codeVerifier.isEmpty) {
      debugPrint(
        '[DropboxAuth] No code verifier found — start authorization first',
      );
      return null;
    }

    try {
      final response = await _dio.post<Map<String, dynamic>>(
        'https://api.dropboxapi.com/oauth2/token',
        data: {
          'code': authorizationCode.trim(),
          'grant_type': 'authorization_code',
          'client_id': appKey,
          'code_verifier': codeVerifier,
        },
        options: Options(
          contentType: Headers.formUrlEncodedContentType,
          sendTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 15),
        ),
      );

      final data = response.data;
      if (data == null) return null;

      debugPrint('[DropboxAuth] Token exchange successful');
      return DropboxTokenResult(
        accessToken: data['access_token'] as String? ?? '',
        refreshToken: data['refresh_token'] as String?,
        expiresIn: data['expires_in'] as int?,
        uid: data['uid'] as String?,
        accountId: data['account_id'] as String?,
      );
    } catch (e) {
      debugPrint('[DropboxAuth] Token exchange failed: $e');
      return null;
    } finally {
      // Clean up verifier
      await _secureStorage.delete(key: _verifierStorageKey);
    }
  }

  /// Uses a stored Dropbox refresh token to obtain a fresh access token.
  Future<DropboxTokenResult?> refreshAccessToken(String refreshToken) async {
    final normalizedRefreshToken = refreshToken.trim();
    if (normalizedRefreshToken.isEmpty) return null;

    try {
      final response = await _dio.post<Map<String, dynamic>>(
        'https://api.dropboxapi.com/oauth2/token',
        data: {
          'grant_type': 'refresh_token',
          'refresh_token': normalizedRefreshToken,
          'client_id': appKey,
        },
        options: Options(
          contentType: Headers.formUrlEncodedContentType,
          sendTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 15),
        ),
      );

      final data = response.data;
      if (data == null) return null;

      debugPrint('[DropboxAuth] Access token refreshed');
      return DropboxTokenResult(
        accessToken: data['access_token'] as String? ?? '',
        refreshToken:
            (data['refresh_token'] as String?) ?? normalizedRefreshToken,
        expiresIn: data['expires_in'] as int?,
        uid: data['uid'] as String?,
        accountId: data['account_id'] as String?,
      );
    } catch (e) {
      debugPrint('[DropboxAuth] Token refresh failed: $e');
      return null;
    }
  }

  /// Checks if there's a pending authorization (verifier exists).
  Future<bool> hasPendingAuthorization() async {
    final verifier = await _secureStorage.read(key: _verifierStorageKey);
    return verifier != null && verifier.isNotEmpty;
  }

  String _generateCodeVerifier() {
    final random = Random.secure();
    final bytes = List<int>.generate(64, (_) => random.nextInt(256));
    return base64UrlEncode(bytes).replaceAll('=', '');
  }

  Future<String> _sha256Challenge(String verifier) async {
    final sha256 = crypto.Sha256();
    final hash = await sha256.hash(utf8.encode(verifier));
    return base64UrlEncode(hash.bytes).replaceAll('=', '');
  }
}

class DropboxTokenResult {
  const DropboxTokenResult({
    required this.accessToken,
    this.refreshToken,
    this.expiresIn,
    this.uid,
    this.accountId,
  });

  final String accessToken;
  final String? refreshToken;
  final int? expiresIn;
  final String? uid;
  final String? accountId;

  bool get isValid => accessToken.trim().isNotEmpty;

  String accessTokenExpiresAtIso({DateTime? now}) {
    final ttlSeconds = expiresIn;
    if (ttlSeconds == null || ttlSeconds <= 0) return '';
    final base = (now ?? DateTime.now()).toUtc();
    return base.add(Duration(seconds: ttlSeconds)).toIso8601String();
  }
}
