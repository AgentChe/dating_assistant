import 'package:dating_assistant/misc/injector.dart';
import 'package:dating_assistant/presentation/analysis/chat_breakdown/chat_breakdown_screen.dart';
import 'package:dating_assistant/presentation/dating_advice/dating_advice/dating_advice_screen.dart';
import 'package:dating_assistant/presentation/dating_advice/dating_advice/dating_advice_view_model.dart';
import 'package:dating_assistant/presentation/main/history/history_screen.dart';
import 'package:dating_assistant/presentation/main/main/main_screen.dart';
import 'package:dating_assistant/presentation/main/main/views/main_tab_bar.dart';
import 'package:dating_assistant/presentation/opening_line/opening_line/opening_line_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';
import 'package:in_app_purchase_platform_interface/in_app_purchase_platform_interface.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import 'fakes/fake_analysis.dart';
import 'fakes/fake_store.dart';

/// Галерея, в которой пользователь сразу выбирает скриншот переписки.
class _FakeImagePicker extends ImagePickerPlatform {
  @override
  Future<XFile?> getImageFromSource({
    required ImageSource source,
    ImagePickerOptions options = const ImagePickerOptions(),
  }) async => XFile.fromData(fakeScreenshot, name: 'chat.png');
}

void main() {
  setUp(() async {
    SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
    InAppPurchasePlatform.instance = FakeStore(isStoreAvailable: false);
    ImagePickerPlatform.instance = _FakeImagePicker();
    await Injector.configure();
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

  Future<void> selectTab(WidgetTester tester, String tab) async {
    await tester.tap(find.descendant(of: find.byType(MainTabBar), matching: find.text(tab)));
    await waitForServer(tester);
  }

  /// У экранов, где шапка — первый элемент списка, VoiceOver читает «Back» вместе с заголовком.
  Future<void> back(WidgetTester tester) async {
    await tester.tap(find.bySemanticsLabel(RegExp('^Back')));
    await tester.pumpAndSettle();
  }

  /// Разговор с коучем на главной: один быстрый ответ — один ответ коуча.
  Future<void> askCoach(WidgetTester tester) async {
    await tester.tap(find.text('Dating advice'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('They stopped replying'));
    await waitForServer(tester);
    await back(tester);
  }

  testWidgets('an empty history offers to analyze a chat, and the breakdown lands in it', (tester) async {
    await openMain(tester);
    await selectTab(tester, 'History');
    expect(find.text('Your conversations land here'), findsOneWidget);
    expect(find.text('Search conversations'), findsNothing);

    await tester.tap(find.text('Analyze a chat'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Scanning'), findsOneWidget);
    await waitForServer(tester);

    // Разбор открылся во вкладке History, таб-бар на месте.
    expect(find.byType(ChatBreakdownScreen), findsOneWidget);
    expect(find.byType(MainTabBar), findsOneWidget);

    await back(tester);
    await waitForServer(tester);
    expect(find.byType(HistoryScreen), findsOneWidget);
    expect(find.text('1 conversation'), findsOneWidget);
    expect(find.text('Nika, 28'), findsOneWidget);
    expect(find.text('Nika is into this — and doing most of the work.'), findsOneWidget);
    expect(find.text('now'), findsOneWidget);

    await tester.tap(find.text('Nika, 28'));
    await waitForServer(tester);
    expect(find.byType(ChatBreakdownScreen), findsOneWidget);
    expect(find.text('Nika is into this'), findsOneWidget);
  });

  testWidgets('a coach conversation reopens from the history and goes on', (tester) async {
    await openMain(tester);
    await askCoach(tester);

    await selectTab(tester, 'History');
    expect(find.text('Dating advice'), findsOneWidget);
    expect(find.text('no pressure — but i still need your verdict on that thing we were debating'), findsOneWidget);

    await tester.tap(find.text('Dating advice'));
    await waitForServer(tester);

    // Коуч открылся поверх таб-бара с тем же разговором, без приветствия.
    expect(find.byType(DatingAdviceScreen), findsOneWidget);
    expect(find.byType(MainTabBar), findsNothing);
    expect(find.text(DatingAdviceViewModel.greeting), findsNothing);
    expect(find.text('They stopped replying'), findsOneWidget);
    expect(find.text('Try sending'), findsOneWidget);

    await tester.tap(find.text('Make it bolder'));
    await waitForServer(tester);
    expect(find.textContaining('Bolder it is'), findsOneWidget);

    // Новый ответ — в той же записи, и она обновилась.
    await back(tester);
    await waitForServer(tester);
    expect(find.text('1 conversation'), findsOneWidget);
    expect(
      find.text('i liked talking to you, so i’ll just say it: up for picking this back up over coffee?'),
      findsOneWidget,
    );
  });

  testWidgets('an opening line session reopens with its line', (tester) async {
    await openMain(tester);
    await tester.tap(find.text('Opening line'));
    await waitForServer(tester);
    await tester.tap(find.text('Just give me one'));
    await waitForServer(tester);
    final line = tester
        .widget<Text>(find.descendant(of: find.byType(OpeningLineScreen), matching: find.byType(Text)).at(1))
        .data!;
    await back(tester);
    await back(tester);

    await selectTab(tester, 'History');
    expect(find.text('Opening line'), findsOneWidget);
    expect(find.text(line), findsOneWidget);

    await tester.tap(find.text('Opening line'));
    await waitForServer(tester);
    expect(find.byType(OpeningLineScreen), findsOneWidget);
    expect(find.text(line), findsOneWidget);
    // Строку не переписали заново: генерация потрачена одна. Экран строится уже после загрузки записи,
    // и счётчик генераций он запрашивает сам — ждём и его.
    await waitForServer(tester);
    expect(find.text('2 of 3 free generations left'), findsOneWidget);
  });

  testWidgets('search narrows the history down and the cross clears it', (tester) async {
    await openMain(tester);
    await tester.tap(find.text('Upload screenshot'));
    await waitForServer(tester);
    await back(tester);
    await askCoach(tester);

    await selectTab(tester, 'History');
    expect(find.text('2 conversations'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'nika');
    await tester.pump();
    expect(find.text('1 conversation'), findsOneWidget);
    expect(find.text('Nika, 28'), findsOneWidget);
    expect(find.text('Dating advice'), findsNothing);

    await tester.enterText(find.byType(TextField), 'tacos');
    await tester.pump();
    expect(find.text('Nothing found'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('Clear search'));
    await tester.pump();
    expect(find.text('2 conversations'), findsOneWidget);
  });
}
