import 'package:shared_preferences/shared_preferences.dart';

/// Сессия пользователя (аналог SessionManager из Swift-проектов).
///
/// Регистрации нет: пользователь анонимный, токен выдаёт сервер при создании
/// профиля на онбординге, дальше приложение подписывает им каждый запрос.
class SessionManager {
  SessionManager(this._preferences);

  static const _tokenKey = 'session.token';

  final SharedPreferencesWithCache _preferences;

  String? get token => _preferences.getString(_tokenKey);

  bool get isAuthorized => token != null;

  Map<String, String> get authHeaders => {if (token case final token?) 'Authorization': 'Bearer $token'};

  Future<void> save({required String token}) => _preferences.setString(_tokenKey, token);
}
