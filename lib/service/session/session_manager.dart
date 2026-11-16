import 'dart:async';

import 'package:dating_assistant/misc/analytics/otter_scale.dart';
import 'package:dating_assistant/service/session/model/subscription.dart';
import 'package:flutter/foundation.dart';

/// Сессия пользователя в OtterScale (аналог SessionManager из Swift-проектов).
///
/// OtterScale выдаёт анонимный идентификатор при установке, а после покупки — внутренний.
/// Ими будем подписывать запросы к нашему серверу; подписку проверяем тоже через SDK.
class SessionManager {
  SessionManager({required this._host, required this._apiKey, OtterScale? otterScale})
    : _otterScale = otterScale ?? OtterScale.shared;

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
      final internalId = _userIds?.internalId;
      _userIds = await _otterScale.userIds();
      if (_userIds?.internalId != internalId) _userIdChanges.add(null);
    } catch (error) {
      debugPrint('SessionManager: cannot read the user ids: $error');
    }
  }

  final _userIdChanges = StreamController<void>.broadcast();

  /// Появился или сменился внутренний идентификатор — после покупки или восстановления.
  Stream<void> get userIdChanges => _userIdChanges.stream;

  Future<bool> hasActiveSubscriptions() async {
    if (!isEnabled) return false;

    try {
      return await _otterScale.hasActiveSubscription();
    } catch (error) {
      debugPrint('SessionManager: cannot check the subscription: $error');
      return false;
    }
  }

  /// Действующая подписка с датой и статусом; null — подписки нет, SDK выключен или не ответил.
  Future<Subscription?> activeSubscription() async {
    if (!isEnabled) return null;

    try {
      final active = [
        for (final subscription in await _otterScale.subscriptions())
          if (subscription.isValid)
            Subscription(
              productId: subscription.productId,
              expiresAt: DateTime.tryParse(subscription.expiration ?? '')?.toLocal(),
              isTrial: subscription.status == 'trial',
              willRenew: subscription.isRenewing,
            ),
      ];
      // Сменил тариф — действуют обе подписки; показываем ту, что закончится позже.
      return active.isEmpty ? null : active.reduce((a, b) => _endOf(b).isAfter(_endOf(a)) ? b : a);
    } catch (error) {
      debugPrint('SessionManager: cannot read the subscriptions: $error');
      return null;
    }
  }

  static DateTime _endOf(Subscription subscription) => subscription.expiresAt ?? DateTime(0);
}
