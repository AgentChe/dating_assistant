import 'dart:convert';

import 'package:dating_assistant/service/profile/model/profile.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Профиль пользователя (аналог ProfileManager из Swift-проектов). Пока хранится только на устройстве.
class ProfileManager {
  ProfileManager(this._preferences);

  static const _profileKey = 'profile';

  final SharedPreferencesWithCache _preferences;

  /// Профиль, сохранённый в конце онбординга; null — онбординг ещё не пройден.
  Profile? get profile {
    final raw = _preferences.getString(_profileKey);
    if (raw == null) return null;

    try {
      return Profile.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (error) {
      // Профиль от старой версии модели: проще пройти онбординг заново, чем упасть на старте.
      debugPrint('ProfileManager: cannot read the saved profile: $error');
      return null;
    }
  }

  Future<void> save(Profile profile) => _preferences.setString(_profileKey, jsonEncode(profile.toJson()));
}
