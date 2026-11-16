import 'package:connectivity_plus_platform_interface/connectivity_plus_platform_interface.dart';
import 'package:dating_assistant/misc/injector.dart';
import 'package:dating_assistant/presentation/analysis/chat_breakdown/chat_breakdown_screen.dart';
import 'package:dating_assistant/presentation/main/home/home_screen.dart';
import 'package:dating_assistant/presentation/main/main/main_screen.dart';
import 'package:dating_assistant/presentation/main/main/views/main_tab_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';
import 'package:in_app_purchase_platform_interface/in_app_purchase_platform_interface.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import 'fakes/fake_analysis.dart';
import 'fakes/fake_otter_scale.dart';
import 'fakes/fake_store.dart';
import 'fakes/fake_connectivity.dart';
import 'fakes/fake_history.dart';

/// Галерея, в которой пользователь сразу выбирает скриншот.
class _FakeImagePicker extends ImagePickerPlatform {
  var picks = 0;

  @override
  Future<XFile?> getImageFromSource({
    required ImageSource source,
    ImagePickerOptions options = const ImagePickerOptions(),
  }) async {
    picks++;
    return XFile.fromData(fakeScreenshot, name: 'screenshot.png');
  }
}

void main() {
  late _FakeImagePicker picker;

  setUp(() async {
    SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
    InAppPurchasePlatform.instance = FakeStore(isStoreAvailable: false);
    picker = _FakeImagePicker();
    ImagePickerPlatform.instance = picker;
    // Сеть «есть», а история — в ящике Hive в памяти.
    ConnectivityPlatform.instance = FakeConnectivity();
    mockOtterScaleChannel();
    await Injector.configure(historyBox: await memoryHistoryBox());
    // Согласие на ИИ уже дано: сам экран согласия проверяет ai_consent_flow_test.
    await Injector.shared.aiConsentManager.setGranted(true);
  });

  /// Ждём моки: задержку сети и «нейросеть», потом анимации. Первый кадр строит экран,
  /// который отправляет запросы, — иначе их таймеры появятся уже после ожидания.
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

  /// «Upload screenshot» сразу открывает галерею, выбранный скриншот уходит на сканирование.
  Future<void> analyzeScreenshot(WidgetTester tester) async {
    await tester.tap(find.text('Upload screenshot'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Analyzing'), findsOneWidget);
    expect(find.text('Scanning'), findsOneWidget);
    // Сканирование закрывает таб-бар.
    expect(find.byType(MainTabBar), findsNothing);

    await waitForServer(tester);
  }

  testWidgets('a screenshot from photos becomes a chat breakdown inside the Main tab', (tester) async {
    await openMain(tester);

    await analyzeScreenshot(tester);

    expect(find.byType(ChatBreakdownScreen), findsOneWidget);
    expect(find.text('Nika, 28'), findsOneWidget);
    expect(find.text('Nika is into this'), findsOneWidget);
    expect(find.byType(MainTabBar), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('Back'));
    await tester.pumpAndSettle();
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.byType(ChatBreakdownScreen), findsNothing);

    // Профиль уже знает про потраченную генерацию.
    await tester.tap(find.descendant(of: find.byType(MainTabBar), matching: find.text('Profile')));
    await waitForServer(tester);
    expect(find.text('2 of 3 free generations left'), findsOneWidget);
  });

  testWidgets('after three free generations Cue Plus opens instead of the gallery', (tester) async {
    await openMain(tester);
    for (var index = 0; index < 3; index++) {
      await analyzeScreenshot(tester);
      await tester.tap(find.bySemanticsLabel('Back'));
      await tester.pumpAndSettle();
    }
    expect(picker.picks, 3);

    await tester.tap(find.text('Upload screenshot'));
    await waitForServer(tester);

    expect(picker.picks, 3);
    expect(find.text('No more counting'), findsOneWidget);
  });

  /// «Upload screenshot» и «назад», пока идёт сканирование.
  Future<void> askToStop(WidgetTester tester) async {
    await tester.tap(find.text('Upload screenshot'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.tap(find.bySemanticsLabel('Back'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Stop analyzing?'), findsOneWidget);
    expect(find.text('Your screenshot won’t be saved.'), findsOneWidget);
  }

  testWidgets('back while scanning asks first, and Keep going still shows the breakdown', (tester) async {
    await openMain(tester);
    await askToStop(tester);

    // Разбор пришёл, пока открыт вопрос, — и ждёт ответа.
    await tester.pump(const Duration(seconds: 5));
    expect(find.text('Stop analyzing?'), findsOneWidget);
    expect(find.byType(ChatBreakdownScreen), findsNothing);

    await tester.tap(find.text('Keep going'));
    await waitForServer(tester);
    expect(find.byType(ChatBreakdownScreen), findsOneWidget);
  });

  testWidgets('Stop leaves nothing behind: no breakdown and nothing in the history', (tester) async {
    await openMain(tester);
    await askToStop(tester);

    await tester.tap(find.text('Stop'));
    await waitForServer(tester);

    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.byType(ChatBreakdownScreen), findsNothing);
    await tester.tap(find.descendant(of: find.byType(MainTabBar), matching: find.text('History')));
    await waitForServer(tester);
    expect(find.text('Your conversations land here'), findsOneWidget);
  });
}
