import 'dart:async';

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
  OtterScale._();

  static final shared = OtterScale._();

  static const _channel = MethodChannel('dating_assistant/otter_scale');

  /// Вызовы из нативного кода слушаем с первой подписки — до неё канал не трогаем.
  late final _receiptValidations = StreamController<void>.broadcast(
    onListen: () => _channel.setMethodCallHandler(_handleNativeCall),
  );

  /// iOS: SDK провалидировал чек — после запуска, покупки и восстановления.
  /// На Android чек проверяет [savePurchase].
  Stream<void> get receiptValidations => _receiptValidations.stream;

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

  /// Android: отдаёт чек Google Play на валидацию и завершается, когда OtterScale его проверил.
  Future<void> savePurchase({
    required String purchaseData,
    required String productId,
    required double price,
    required String currency,
  }) => _channel.invokeMethod<void>('save_purchase', {
    'purchase_data': purchaseData,
    'product_id': productId,
    'price': price,
    'currency': currency,
  });

  Future<void> _handleNativeCall(MethodCall call) async {
    if (call.method == 'receipt_validated') _receiptValidations.add(null);
  }
}
