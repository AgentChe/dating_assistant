import 'package:flutter/services.dart';

/// Идентификаторы пользователя в OtterScale.
class OtterScaleUserIds {
  const OtterScaleUserIds({required this.anonymousId, this.internalId});

  /// Выдаётся при установке приложения.
  final String anonymousId;

  /// Появляется после покупки или привязки; до этого null.
  final String? internalId;
}

/// Мост к нативному SDK OtterScale: на iOS — под OtterScaleiOS, на Android — otterscale.aar.
///
/// Нативная сторона канала: ios/Runner/OtterScaleBridge.swift и
/// android/app/src/main/kotlin/com/example/dating_assistant/OtterScaleBridge.kt.
class OtterScale {
  const OtterScale();

  static const _channel = MethodChannel('dating_assistant/otter_scale');

  /// Запускает SDK и завершается, когда он готов: на iOS — после первой валидации чека,
  /// на Android — после регистрации установки.
  Future<void> initialize({required String host, required String apiKey}) =>
      _channel.invokeMethod<void>('initialize', {'host': host, 'api_key': apiKey});

  Future<OtterScaleUserIds> userIds() async {
    final ids = await _channel.invokeMapMethod<String, Object?>('get_user_ids') ?? const {};
    return OtterScaleUserIds(anonymousId: ids['anonymous'] as String? ?? '', internalId: ids['internal'] as String?);
  }

  /// Есть ли действующая подписка или вечная покупка.
  Future<bool> hasActiveSubscription() async => await _channel.invokeMethod<bool>('has_active_subscription') ?? false;
}
