import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ThemePreference {
  static const _key = 'credence_theme_mode';
  static const FlutterSecureStorage _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  static Future<ThemeMode> load() async {
    final value = await _storage.read(key: _key);
    return switch (value) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
  }

  static Future<void> save(ThemeMode mode) async {
    await _storage.write(key: _key, value: mode.name);
  }
}
