import 'dart:async';

import 'package:dating_assistant/misc/global_definitions.dart';
import 'package:dating_assistant/service/analytics/analytics_client.dart';
import 'package:dating_assistant/service/session/session_manager.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Имена событий — как в остальных приложениях студии.
abstract final class AnalyticsEvents {
  static const firstLaunch = 'First Launch';

  static const paygateScreen = 'Paygate Screen';

  static const homeScreen = 'Home Screen';

  static const userIdSynced = 'UserIDSynced';
}

/// Аналитика в Amplitude (аналог AmplitudeManager из Swift-приложений). Как там, у каждого события есть
/// `anonymous_id` из OtterScale и `app` — метка приложения: проект в Amplitude общий для приложений студии.
///
/// Когда OtterScale узнаёт внутренний id пользователя (после проверки чека), он становится user id
/// в Amplitude, а для каждого нового id один раз приходит событие UserIDSynced.
class AnalyticsManager {
  AnalyticsManager({
    required this._sessionManager,
    required this._preferences,
    AnalyticsClient? client,
  }) : _client = client ?? AmplitudeAnalyticsClient();

  static const _firstLaunchKey = 'analytics.first_launch_logged';

  static const _syncedUserIdKey = 'analytics.synced_user_id';

  final SessionManager _sessionManager;

  final SharedPreferencesWithCache _preferences;

  final AnalyticsClient _client;

  var _isStarted = false;

  StreamSubscription<void>? _userIdChanges;

  /// Запускается со сплэша после OtterScale — тогда у событий уже есть anonymous_id.
  Future<void> start() async {
    if (_isStarted) return;
    _isStarted = true;

    try {
      _client.start(GlobalDefinitions.amplitudeApiKey);
    } catch (error) {
      debugPrint('AnalyticsManager: cannot start Amplitude: $error');
    }

    if (_preferences.getBool(_firstLaunchKey) != true) {
      await _preferences.setBool(_firstLaunchKey, true);
      logEvent(AnalyticsEvents.firstLaunch);
    }

    _userIdChanges = _sessionManager.userIdChanges.listen((_) => _syncUserId());
    await _syncUserId();
  }

  /// До [start] события никуда не уходят: Amplitude запускается со сплэша.
  void logEvent(String name, [Map<String, Object?> properties = const {}]) {
    if (!_isStarted) return;

    final anonymousId = _sessionManager.anonymousId;
    final eventProperties = {...properties, 'anonymous_id': ?anonymousId, 'app': GlobalDefinitions.applicationTag};
    unawaited(
      _client
          .track(name, eventProperties)
          .catchError((Object error) => debugPrint('AnalyticsManager: cannot log $name: $error')),
    );
  }

  void dispose() => _userIdChanges?.cancel();

  Future<void> _syncUserId() async {
    final userId = _sessionManager.internalId;
    if (userId == null || userId.isEmpty || userId == _sessionManager.anonymousId) return;

    try {
      await _client.setUserId(userId);
    } catch (error) {
      debugPrint('AnalyticsManager: cannot set the user id: $error');
      return;
    }

    if (_preferences.getString(_syncedUserIdKey) == userId) return;
    await _preferences.setString(_syncedUserIdKey, userId);
    logEvent(AnalyticsEvents.userIdSynced);
  }
}
