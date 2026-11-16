import 'package:dating_assistant/service/analytics/analytics_manager.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import '../fakes/fake_analytics.dart';
import '../fakes/fake_managers.dart';

void main() {
  late SharedPreferencesWithCache preferences;
  late FakeSessionManager session;
  late FakeAnalyticsClient amplitude;

  setUp(() async {
    SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
    preferences = await SharedPreferencesWithCache.create(cacheOptions: const SharedPreferencesWithCacheOptions());
    session = FakeSessionManager(isPlus: false);
    amplitude = FakeAnalyticsClient();
  });

  /// Новый запуск приложения: тот же телефон, новый менеджер.
  AnalyticsManager launch() => AnalyticsManager(sessionManager: session, preferences: preferences, client: amplitude);

  List<String> eventNames() => [for (final (name, _) in amplitude.events) name];

  test('nothing is sent before the splash starts Amplitude', () async {
    launch().logEvent(AnalyticsEvents.homeScreen);
    await pumpEventQueue();

    expect(amplitude.apiKey, isNull);
    expect(amplitude.events, isEmpty);
  });

  test('the first launch is logged once, and every event carries anonymous_id and app', () async {
    final analytics = launch();
    await analytics.start();
    analytics.logEvent(AnalyticsEvents.paygateScreen);
    await pumpEventQueue();

    expect(amplitude.apiKey, '0d810afcbd45c0b58a5ed6cd272acfa');
    expect(eventNames(), ['First Launch', 'Paygate Screen']);
    for (final (_, properties) in amplitude.events) {
      expect(properties, {'anonymous_id': 'anonymous-1', 'app': 'DATING_ASSISTANT'});
    }

    await launch().start();
    await pumpEventQueue();
    expect(eventNames(), ['First Launch', 'Paygate Screen']);
  });

  test('the OtterScale id becomes the Amplitude user id, and UserIDSynced comes once per id', () async {
    session.internalUserId = 'otter-1';
    await launch().start();
    await pumpEventQueue();
    expect(amplitude.userIds, ['otter-1']);
    expect(eventNames(), ['First Launch', 'UserIDSynced']);

    // Следующий запуск: user id ставится снова, событие не повторяется.
    await launch().start();
    await pumpEventQueue();
    expect(amplitude.userIds, ['otter-1', 'otter-1']);
    expect(eventNames(), ['First Launch', 'UserIDSynced']);

    // Покупка на другом аккаунте App Store — новый id.
    session.changeInternalId('otter-2');
    await pumpEventQueue();
    expect(amplitude.userIds.last, 'otter-2');
    expect(eventNames(), ['First Launch', 'UserIDSynced', 'UserIDSynced']);
  });

  test('until OtterScale knows the user, there is no user id to sync', () async {
    await launch().start();
    await pumpEventQueue();

    expect(amplitude.userIds, isEmpty);
    expect(eventNames(), ['First Launch']);
  });
}
