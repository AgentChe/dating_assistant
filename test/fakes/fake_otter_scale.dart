import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Нативной части OtterScale в тестах нет, а ответа незнакомого канала виджет-тест не дождётся.
/// Канал отвечает как у новой установки без подписки.
void mockOtterScaleChannel({bool hasSubscription = false}) {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
    const MethodChannel('dating_assistant/otter_scale'),
    (call) async => switch (call.method) {
      'has_active_subscription' => hasSubscription,
      'get_user_ids' => {'anonymous': 'anonymous-1'},
      'get_subscriptions' => <Object?>[],
      _ => null,
    },
  );
}
