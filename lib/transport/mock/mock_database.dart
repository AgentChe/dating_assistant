import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// «База данных» фейкового сервера. Лежит в SharedPreferences, поэтому данные
/// переживают перезапуск приложения, как на настоящем сервере.
class MockDatabase {
  MockDatabase(this._preferences);

  static const _keyPrefix = 'mock_db.';

  final SharedPreferencesWithCache _preferences;

  Map<String, dynamic>? read(String key) {
    final raw = _preferences.getString('$_keyPrefix$key');
    return raw == null ? null : jsonDecode(raw) as Map<String, dynamic>;
  }

  Future<void> write(String key, Map<String, dynamic> value) =>
      _preferences.setString('$_keyPrefix$key', jsonEncode(value));
}
