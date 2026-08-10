import 'dart:convert';

import 'package:cryptography/cryptography.dart';
import 'package:dio/dio.dart';

class BreachCheckService {
  BreachCheckService({Dio? dio}) : _dio = dio ?? Dio();

  final Dio _dio;

  /// Checks if a password has been found in known data breaches.
  /// Uses the HIBP k-anonymity API — only sends the first 5 chars of the
  /// SHA-1 hash, so the full password never leaves the device.
  /// Returns the number of times the password was seen in breaches, or 0 if
  /// clean.
  Future<int> checkPassword(String password) async {
    if (password.isEmpty) {
      return 0;
    }

    try {
      final sha1Algorithm = Sha1();
      final hash = await sha1Algorithm.hash(utf8.encode(password));
      final hexHash = hash.bytes
          .map((b) => b.toRadixString(16).padLeft(2, '0'))
          .join()
          .toUpperCase();

      final prefix = hexHash.substring(0, 5);
      final suffix = hexHash.substring(5);

      final response = await _dio.get<String>(
        'https://api.pwnedpasswords.com/range/$prefix',
        options: Options(
          responseType: ResponseType.plain,
          headers: {
            'Add-Padding': 'true',
            'User-Agent': 'Credence-PasswordManager',
          },
        ),
      );

      if (response.statusCode != 200 || response.data == null) {
        return 0;
      }

      final lines = response.data!.split('\n');
      for (final line in lines) {
        final parts = line.trim().split(':');
        if (parts.length == 2 && parts[0].toUpperCase() == suffix) {
          return int.tryParse(parts[1].trim()) ?? 0;
        }
      }

      return 0;
    } catch (_) {
      // Network errors should not block credential creation.
      return 0;
    }
  }
}
