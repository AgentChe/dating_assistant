import 'package:connectivity_plus_platform_interface/connectivity_plus_platform_interface.dart';
import 'package:dating_assistant/misc/custom_views/glass_button.dart';
import 'package:dating_assistant/misc/injector.dart';
import 'package:dating_assistant/presentation/analysis/chat_breakdown/chat_breakdown_screen.dart';
import 'package:dating_assistant/presentation/consent/ai_consent_screen.dart';
import 'package:dating_assistant/presentation/main/main/main_screen.dart';
import 'package:dating_assistant/presentation/main/main/views/main_tab_bar.dart';
import 'package:dating_assistant/presentation/main/profile/ai_privacy/ai_privacy_screen.dart';
import 'package:dating_assistant/presentation/splash/onboarding/onboarding_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';
import 'package:in_app_purchase_platform_interface/in_app_purchase_platform_interface.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import 'fakes/fake_analysis.dart';
import 'fakes/fake_connectivity.dart';
import 'fakes/fake_history.dart';
import 'fakes/fake_otter_scale.dart';
import 'fakes/fake_store.dart';

/// Галерея, которая считает, сколько раз её открыли.
class _CountingImagePicker extends ImagePickerPlatform {
  var opened = 0;

  @override
  Future<XFile?> getImageFromSource({
    required ImageSource source,
    ImagePickerOptions options = const ImagePickerOptions(),
  }) async {
    opened++;
    return XFile.fromData(fakeScreenshot, name: 'chat.png');
  }
}

void main() {
  late _CountingImagePicker gallery;

  setUp(() async {
    SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
    InAppPurchasePlatform.instance = FakeStore(isStoreAvailable: false);
    ImagePickerPlatform.instance = gallery = _CountingImagePicker();
    ConnectivityPlatform.instance = FakeConnectivity();
    mockOtterScaleChannel();
    // Согласия ещё нет — как у нового пользователя.
    await Injector.configure(historyBox: await memoryHistoryBox());
  });

  Future<void> waitForServer(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  }

  Future<void> openMain(WidgetTester tester) async {
    tester.view
      ..physicalSize = const Size(1284, 2778)
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const MaterialApp(home: MainScreen()));
    await waitForServer(tester);
  }

  Future<void> selectTab(WidgetTester tester, String tab) async {
    await tester.tap(find.descendant(of: find.byType(MainTabBar), matching: find.text(tab)));
    await waitForServer(tester);
  }

  /// Нажатие на то, что ниже экрана: в тестах шрифт шире настоящего, и экраны прокручиваются.
  Future<void> tapVisible(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
  }

  const question = 'Allow Cue to share your chats with AI?';
  const nothingSent = 'Nothing was sent. Allow AI when you’re ready';

  testWidgets('the gallery waits for the consent: Not now sends nothing, Allow and continue analyzes', (tester) async {
    await openMain(tester);

    await tester.tap(find.text('Upload screenshot'));
    await tester.pumpAndSettle();
    expect(find.byType(AiConsentScreen), findsOneWidget);
    expect(find.text(question), findsOneWidget);
    expect(find.text('Analyzed by Google Gemini'), findsOneWidget);
    expect(gallery.opened, 0);

    await tapVisible(tester, find.text('Not now'));
    await tester.pumpAndSettle();
    expect(find.byType(AiConsentScreen), findsNothing);
    expect(find.text(nothingSent), findsOneWidget);
    expect(gallery.opened, 0);
    expect(Injector.shared.historyManager.obtainHistory(), isEmpty);
    expect(Injector.shared.aiConsentManager.isGranted, isFalse);
    // Плашка уходит сама.
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
    expect(find.text(nothingSent), findsNothing);

    await tester.tap(find.text('Upload screenshot'));
    await tester.pumpAndSettle();
    await tapVisible(tester, find.text('Allow and continue'));
    await waitForServer(tester);

    expect(gallery.opened, 1);
    expect(find.byType(ChatBreakdownScreen), findsOneWidget);
    expect(Injector.shared.aiConsentManager.isGranted, isTrue);
  });

  testWidgets('AI & privacy turns sharing off, and the next request asks again', (tester) async {
    await Injector.shared.aiConsentManager.setGranted(true);
    await openMain(tester);
    await selectTab(tester, 'Profile');
    expect(find.text('AI & privacy'), findsOneWidget);
    expect(find.text('On'), findsOneWidget);

    await tester.tap(find.text('AI & privacy'));
    await tester.pumpAndSettle();
    expect(find.byType(AiPrivacyScreen), findsOneWidget);
    expect(find.byType(MainTabBar), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('Share chats with AI'));
    await tester.pumpAndSettle();
    expect(
      find.text('Off. Nothing is sent to AI, so breakdowns, the coach and opening lines are paused.'),
      findsOneWidget,
    );
    expect(Injector.shared.aiConsentManager.isGranted, isFalse);

    await tester.tap(find.descendant(of: find.byType(AiPrivacyScreen), matching: find.byType(GlassButton)));
    await tester.pumpAndSettle();
    expect(find.text('Off'), findsOneWidget);

    await selectTab(tester, 'Main');
    await tester.tap(find.text('Upload screenshot'));
    await tester.pumpAndSettle();
    expect(find.text(question), findsOneWidget);
    await tapVisible(tester, find.text('Not now'));
    await tester.pumpAndSettle();
    expect(gallery.opened, 0);
  });

  testWidgets('Delete my data asks first, erases the history and the answers, and starts over', (tester) async {
    await Injector.shared.aiConsentManager.setGranted(true);
    await openMain(tester);
    await tester.tap(find.text('Upload screenshot'));
    await waitForServer(tester);
    expect(Injector.shared.historyManager.obtainHistory(), hasLength(1));

    await selectTab(tester, 'Profile');
    await tester.tap(find.text('AI & privacy'));
    await tester.pumpAndSettle();
    await tapVisible(tester, find.text('Delete my data'));
    await tester.pumpAndSettle();
    expect(find.text('Delete your data?'), findsOneWidget);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(Injector.shared.historyManager.obtainHistory(), hasLength(1));

    await tapVisible(tester, find.text('Delete my data'));
    await tester.pumpAndSettle();
    // Кнопка окна — поверх строки с тем же текстом.
    await tester.tap(find.text('Delete my data').last);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.byType(OnboardingScreen), findsOneWidget);
    expect(find.byType(MainScreen), findsNothing);
    expect(Injector.shared.historyManager.obtainHistory(), isEmpty);
    expect(Injector.shared.profileManager.profile, isNull);
    expect(Injector.shared.aiConsentManager.isGranted, isFalse);
  });
}
