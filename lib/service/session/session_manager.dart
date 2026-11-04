import 'dart:async';

import 'package:dating_assistant/misc/analytics/otter_scale.dart';
import 'package:flutter/foundation.dart';

/// Сессия пользователя в OtterScale (аналог SessionManager из Swift-проектов).
///
/// OtterScale выдаёт анонимный идентификатор при установке, а после покупки — внутренний.
/// Ими будем подписывать запросы к нашему серверу; подписку проверяем тоже через SDK.
class SessionManager {
  SessionManager({required String host, required String apiKey, OtterScale? otterScale})
    : _host = host,
      _apiKey = apiKey,
      _otterScale = otterScale ?? OtterScale.shared;

  final String _host;

  final String _apiKey;

  final OtterScale _otterScale;

  OtterScaleUserIds? _userIds;

  /// SDK включён: ключ приложения задан в GlobalDefinitions.
  bool get isEnabled => _apiKey.isNotEmpty;

  /// null, пока SDK не запущен ([start]).
  String? get anonymousId => _userIds?.anonymousId;

  String? get internalId => _userIds?.internalId;

  /// Запускает SDK и получает идентификаторы. Вызывается со сплэша и ждёт не дольше [timeout],
  /// чтобы старт приложения не зависел от сети.
  Future<void> start({Duration timeout = const Duration(seconds: 5)}) async {
    if (!isEnabled) {
      debugPrint('SessionManager: OtterScale API key is not set, the SDK stays off');
      return;
    }

    try {
      await _otterScale.initialize(host: _host, apiKey: _apiKey).timeout(timeout);
      _userIds = await _otterScale.userIds();
    } catch (error) {
      // Приложение работает и без SDK: идентификаторы получим при следующем запуске.
      debugPrint('SessionManager: OtterScale is not ready: $error');
    }
  }

  /// Перечитывает идентификаторы — после покупки появляется внутренний.
  Future<void> refreshUserIds() async {
    if (!isEnabled) return;

    try {
      _userIds = await _otterScale.userIds();
    } catch (error) {
      debugPrint('SessionManager: cannot read the user ids: $error');
    }
  }

  Future<bool> hasActiveSubscriptions() async {
    if (!isEnabled) return false;

    try {
      return await _otterScale.hasActiveSubscription();
    } catch (error) {
      debugPrint('SessionManager: cannot check the subscription: $error');
      return false;
    }
  }
}
