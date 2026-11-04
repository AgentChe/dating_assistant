import 'package:dating_assistant/misc/app.dart';
import 'package:dating_assistant/misc/custom_views/glass_button.dart';
import 'package:dating_assistant/misc/injector.dart';
import 'package:dating_assistant/presentation/main/home/home_screen.dart';
import 'package:dating_assistant/presentation/main/main/views/main_tab_bar.dart';
import 'package:dating_assistant/service/profile/model/voice.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase_platform_interface/in_app_purchase_platform_interface.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import 'fakes/fake_store.dart';

void main() {
  testWidgets('a new user goes through onboarding and lands on the main screen', (tester) async {
    // Размер iPhone из макета: 428×926.
    tester.view
      ..physicalSize = const Size(1284, 2778)
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
    InAppPurchasePlatform.instance = FakeStore(isStoreAvailable: false);
    await Injector.configure();

    Future<void> tap(String text) async {
      await tester.tap(find.text(text).last);
      await tester.pumpAndSettle();
    }

    await tester.pumpWidget(const App());
    await tester.pumpAndSettle();
    expect(find.text('Never wonder what to text again'), findsOneWidget);

    await tap('Get started');
    await tester.enterText(find.byType(TextField), 'Alex');
    await tester.pump();
    await tap('Continue');

    expect(find.text('Nice to meet you, Alex 👋\nWhat are you looking for?'), findsOneWidget);
    await tap('A relationship');
    await tap('Continue');

    await tap('Man');
    await tap('25–34');
    await tap('Continue');

    await tap('Keeping it going');
    await tap('Knowing if they’re into me');
    await tap('Continue');

    expect(find.text('Knowing if they’re into you'), findsOneWidget);
    await tap('Continue');

    expect(find.text('Your voice · 1 of 3'), findsOneWidget);
    await tap('That’s me');
    expect(find.text('Your voice · 2 of 3'), findsOneWidget);
    await tap('Not me');
    await tap('That’s me');

    expect(find.text('That’s your voice, Alex'), findsOneWidget);
    expect(find.text('no emoji'), findsOneWidget);
    await tap('Sounds like me');

    await tap('lucky! where did you go?');
    await tap('Continue');
    expect(find.text('You asked where — Nika already said. Cue asks why, so the chat keeps going.'), findsOneWidget);
    await tap('Continue');

    expect(find.text('Tuning Cue to you, Alex'), findsOneWidget);
    await tester.pump(const Duration(seconds: 5));
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();

    expect(find.text('Alex, your Cue is ready'), findsOneWidget);
    expect(find.text('Warm · 2 of 5'), findsOneWidget);
    expect(find.text('lowercase, no emoji, direct'), findsOneWidget);
    await tap('Analyze my first chat');

    // Подписки нет — пейгейт; в тестах магазин недоступен, поэтому тарифы не загрузились.
    expect(find.text('Keep the chat going'), findsOneWidget);
    expect(find.textContaining('Couldn’t load the plans.', findRichText: true), findsOneWidget);
    await tester.tap(find.byType(GlassButton));
    await tester.pumpAndSettle();

    expect(find.byType(MainTabBar), findsOneWidget);
    expect(find.byType(HomeScreen), findsOneWidget);
    final profile = Injector.shared.profileManager.profile!;
    expect(profile.name, 'Alex');
    expect(profile.voice.traits, {VoiceTrait.lowercase, VoiceTrait.direct});
  });
}
