import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Где лежит счётчик бесплатных генераций.
abstract interface class UsageStorage {
  Future<String?> read();

  Future<void> write(String value);
}

/// Счётчик на устройстве. На iOS — в Keychain: его записи система не удаляет вместе с приложением,
/// поэтому переустановка не возвращает бесплатные генерации. На Android похожего места нет:
/// там счётчик в настройках приложения и стирается вместе с ним.
class DeviceUsageStorage implements UsageStorage {
  DeviceUsageStorage(this._preferences, {this._keychain = const FlutterSecureStorage()});

  static const _key = 'free_generations';

  final SharedPreferencesWithCache _preferences;

  final FlutterSecureStorage _keychain;

  bool get _usesKeychain => defaultTargetPlatform == TargetPlatform.iOS;

  @override
  Future<String?> read() async => _usesKeychain ? _keychain.read(key: _key) : _preferences.getString(_key);

  @override
  Future<void> write(String value) =>
      _usesKeychain ? _keychain.write(key: _key, value: value) : _preferences.setString(_key, value);
}
