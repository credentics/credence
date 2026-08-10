import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:pass_doc_manager/app/config/oauth_config.dart';
import 'package:url_launcher/url_launcher.dart';

/// Handles Google Drive OAuth 2.0 with a local loopback server.
///
/// Flow (fully automatic — no code pasting):
/// 1. Start a local HTTP server on a random port
/// 2. Open browser to Google auth URL with redirect_uri=http://localhost:{port}
/// 3. User approves in browser
/// 4. Google redirects to localhost:{port}?code=XXX
/// 5. Local server catches the redirect, extracts the code
/// 6. Exchanges code for access token
/// 7. Returns token — done
class GoogleDriveAuthService {
  GoogleDriveAuthService({Dio? dio}) : _dio = dio ?? Dio();

  final Dio _dio;

  static String get clientId => OAuthConfig.googleDriveClientId;
  static const String _scope = 'https://www.googleapis.com/auth/drive.file';

  /// Runs the full OAuth flow: opens browser, catches redirect, returns token.
  /// Returns null if the user cancels or an error occurs.
  Future<GoogleDriveTokenResult?> authorize() async {
    HttpServer? server;
    try {
      // 1. Start local server on a random available port
      server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      final port = server.port;
      final redirectUri = 'http://localhost:$port';
      final codeVerifier = _generateCodeVerifier();

      debugPrint('[GoogleDriveAuth] Local server started on port $port');

      // 2. Open browser
      final authUrl = Uri.https('accounts.google.com', '/o/oauth2/v2/auth', {
        'client_id': clientId,
        'response_type': 'code',
        'scope': _scope,
        'redirect_uri': redirectUri,
        'code_challenge': codeVerifier,
        'code_challenge_method': 'plain',
        'access_type': 'offline',
        'prompt': 'consent',
      });

      debugPrint('[GoogleDriveAuth] Opening browser for authorization');
      await launchUrl(authUrl, mode: LaunchMode.externalApplication);

      // 3. Wait for the redirect (with timeout)
      final code = await _waitForCode(server).timeout(
        const Duration(minutes: 5),
        onTimeout: () => null,
      );

      if (code == null || code.isEmpty) {
        debugPrint('[GoogleDriveAuth] No authorization code received');
        return null;
      }

      debugPrint('[GoogleDriveAuth] Authorization code received');

      // 4. Exchange code for token
      final response = await _dio.post<Map<String, dynamic>>(
        'https://oauth2.googleapis.com/token',
        data: {
          'code': code,
          'grant_type': 'authorization_code',
          'client_id': clientId,
          'redirect_uri': redirectUri,
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

      debugPrint('[GoogleDriveAuth] Token exchange successful');
      return GoogleDriveTokenResult(
        accessToken: data['access_token'] as String? ?? '',
        refreshToken: data['refresh_token'] as String?,
        expiresIn: data['expires_in'] as int?,
      );
    } catch (e) {
      debugPrint('[GoogleDriveAuth] Authorization failed: $e');
      return null;
    } finally {
      await server?.close(force: true);
    }
  }

  /// Waits for Google to redirect to our local server and extracts the code.
  Future<String?> _waitForCode(HttpServer server) async {
    await for (final request in server) {
      final uri = request.uri;
      final code = uri.queryParameters['code'];
      final error = uri.queryParameters['error'];

      if (error != null) {
        // User denied access
        request.response
          ..statusCode = HttpStatus.ok
          ..headers.contentType = ContentType.html
          ..write(_buildHtmlResponse(
            title: 'Authorization Denied',
            message: 'You can close this window.',
            success: false,
          ));
        await request.response.close();
        return null;
      }

      if (code != null && code.isNotEmpty) {
        // Success — show a nice confirmation page
        request.response
          ..statusCode = HttpStatus.ok
          ..headers.contentType = ContentType.html
          ..write(_buildHtmlResponse(
            title: 'Connected!',
            message:
                'Google Drive is now connected to Credence. You can close this window.',
            success: true,
          ));
        await request.response.close();
        return code;
      }

      // Unknown request — ignore
      request.response
        ..statusCode = HttpStatus.notFound
        ..write('Not found');
      await request.response.close();
    }
    return null;
  }

  String _buildHtmlResponse({
    required String title,
    required String message,
    required bool success,
  }) {
    final color = success ? '#2E7D32' : '#E53E3E';
    final icon = success ? '&#10004;' : '&#10008;';
    return '''
<!DOCTYPE html>
<html>
<head><title>Credence - $title</title></head>
<body style="font-family:-apple-system,BlinkMacSystemFont,sans-serif;display:flex;align-items:center;justify-content:center;height:100vh;margin:0;background:#f5f6fa;">
  <div style="text-align:center;padding:40px;background:white;border-radius:16px;box-shadow:0 4px 20px rgba(0,0,0,0.08);max-width:400px;">
    <div style="font-size:48px;color:$color;margin-bottom:16px;">$icon</div>
    <h1 style="font-size:24px;color:#1a1a2e;margin:0 0 8px;">$title</h1>
    <p style="font-size:14px;color:#666;margin:0;">$message</p>
  </div>
</body>
</html>
''';
  }

  String _generateCodeVerifier() {
    final random = Random.secure();
    final bytes = List<int>.generate(64, (_) => random.nextInt(256));
    return base64UrlEncode(bytes).replaceAll('=', '');
  }
}

class GoogleDriveTokenResult {
  const GoogleDriveTokenResult({
    required this.accessToken,
    this.refreshToken,
    this.expiresIn,
  });

  final String accessToken;
  final String? refreshToken;
  final int? expiresIn;

  bool get isValid => accessToken.trim().isNotEmpty;
}
