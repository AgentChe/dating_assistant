import 'package:dating_assistant/service/consent/ai_consent_manager.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import '../fakes/fake_analysis.dart';
import '../fakes/fake_consent.dart';

void main() {
  late SharedPreferencesWithCache preferences;
  late AiConsentManager consent;
  late List<bool> changes;
  late int questions;

  setUp(() async {
    SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
    preferences = await SharedPreferencesWithCache.create(cacheOptions: const SharedPreferencesWithCacheOptions());
    consent = AiConsentManager(preferences);
    changes = [];
    consent.changes.listen(changes.add);
    questions = 0;
  });

  void answer(bool isAllowed) => consent.askUser = () async {
    questions++;
    return isAllowed;
  };

  test('nothing is allowed until the user says so', () async {
    expect(consent.isGranted, isFalse);
    // Спросить некому — значит, не разрешено.
    await expectLater(consent.ensureGranted(), throwsA(isA<AiConsentDeclined>()));
  });

  test('Not now keeps it off and the request does not go', () async {
    answer(false);

    final error = await consent.ensureGranted().then<Object?>((_) => null, onError: (Object error) => error);

    expect(AiConsentManager.isDeclined(error!), isTrue);
    expect(consent.isGranted, isFalse);
    expect(changes, isEmpty);
  });

  test('Allow and continue is asked once, even for two requests at a time, and remembered', () async {
    answer(true);

    await Future.wait([consent.ensureGranted(), consent.ensureGranted()]);
    await consent.ensureGranted();
    await pumpEventQueue();

    expect(questions, 1);
    expect(consent.isGranted, isTrue);
    expect(changes, [true]);
    // Новый запуск читает то же согласие.
    expect(AiConsentManager(preferences).isGranted, isTrue);
  });

  test('turned off in the profile, it is asked for again', () async {
    answer(true);
    await consent.ensureGranted();

    await consent.setGranted(false);
    await consent.ensureGranted();
    await pumpEventQueue();

    expect(questions, 2);
    expect(changes, [true, false, true]);
  });

  test('without consent the screenshot never reaches the server and costs no generation', () async {
    final consent = FakeAiConsentManager(isGranted: false)..askUser = () async => false;
    final analysis = await mockAnalysisManager(consentManager: consent);

    await expectLater(analysis.analyzeScreenshot(fakeScreenshot), throwsA(isA<AiConsentDeclined>()));

    expect(consent.asks, 1);
    // Разрешили — тот же скриншот разбирается.
    consent.askUser = () async => true;
    expect((await analysis.analyzeScreenshot(fakeScreenshot)).partner.name, 'Nika');
  });
}
