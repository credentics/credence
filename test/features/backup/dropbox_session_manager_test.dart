import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pass_doc_manager/features/backup/presentation/cubit/dropbox_session_manager.dart';

void main() {
  group('DropboxSessionManager.isAuthError', () {
    test('true for a Dio 401 response', () {
      final error = DioException(
        requestOptions: RequestOptions(path: '/x'),
        response: Response(
          requestOptions: RequestOptions(path: '/x'),
          statusCode: 401,
        ),
      );
      expect(DropboxSessionManager.isAuthError(error), isTrue);
    });

    test('true for known expired/invalid-token messages', () {
      for (final msg in const [
        'HTTP 401 unauthorized',
        'expired_access_token',
        'invalid_access_token',
        'invalid_token',
      ]) {
        expect(
          DropboxSessionManager.isAuthError(Exception(msg)),
          isTrue,
          reason: msg,
        );
      }
    });

    test('false for unrelated errors', () {
      expect(DropboxSessionManager.isAuthError(Exception('network down')), isFalse);
      final error = DioException(
        requestOptions: RequestOptions(path: '/x'),
        response: Response(
          requestOptions: RequestOptions(path: '/x'),
          statusCode: 500,
        ),
      );
      expect(DropboxSessionManager.isAuthError(error), isFalse);
    });
  });
}
