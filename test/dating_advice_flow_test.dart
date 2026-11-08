import 'package:connectivity_plus_platform_interface/connectivity_plus_platform_interface.dart';
import 'package:dating_assistant/misc/injector.dart';
import 'package:dating_assistant/presentation/analysis/chat_breakdown/chat_breakdown_screen.dart';
import 'package:dating_assistant/presentation/dating_advice/dating_advice/dating_advice_screen.dart';
import 'package:dating_assistant/presentation/dating_advice/dating_advice/dating_advice_view_model.dart';
import 'package:dating_assistant/presentation/dating_advice/dating_advice/views/quick_replies.dart';
import 'package:dating_assistant/presentation/main/home/home_screen.dart';
import 'package:dating_assistant/presentation/main/main/main_screen.dart';
import 'package:dating_assistant/presentation/main/main/views/main_tab_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';
import 'package:in_app_purchase_platform_interface/in_app_purchase_platform_interface.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import 'fakes/fake_analysis.dart';
import 'fakes/fake_store.dart';
import 'fakes/fake_connectivity.dart';
import 'fakes/fake_history.dart';

/// Галерея, в которой пользователь сразу выбирает скриншот переписки.
class _FakeImagePicker extends ImagePickerPlatform {
  @override
  Future<XFile?> getImageFromSource({
    required ImageSource source,
    ImagePickerOptions options = const ImagePickerOptions(),
  }) async => XFile.fromData(fakeScreenshot, name: 'chat.png');
}

void main() {
  late String? clipboard;

  setUp(() async {
    SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
    InAppPurchasePlatform.instance = FakeStore(isStoreAvailable: false);
    ImagePickerPlatform.instance = _FakeImagePicker();
    // Сеть «есть», а история — в ящике Hive в памяти.
    ConnectivityPlatform.instance = FakeConnectivity();
    await Injector.configure(historyBox: await memoryHistoryBox());
    clipboard = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') clipboard = (call.arguments as Map)['text'] as String?;
        return null;
      },
    );
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

  Future<void> openDatingAdvice(WidgetTester tester) async {
    await openMain(tester);
    await tester.tap(find.text('Dating advice'));
    await tester.pumpAndSettle();
    expect(find.byType(DatingAdviceScreen), findsOneWidget);
  }

  /// Чип над полем ввода. Тестовый шрифт шире настоящего, поэтому ряд чипов сначала прокручиваем к нужному.
  Future<Finder> quickReply(WidgetTester tester, String text) async {
    final chip = find.descendant(
      of: find.byType(QuickReplies),
      matching: find.text(text, skipOffstage: false),
      skipOffstage: false,
    );
    await tester.ensureVisible(chip);
    await tester.pumpAndSettle();
    return chip;
  }

  /// Быстрый ответ: вопрос сразу в ленте, коуч печатает, потом отвечает.
  Future<void> ask(WidgetTester tester, String text) async {
    await tester.tap(await quickReply(tester, text));
    await tester.pump();
    expect(find.bySemanticsLabel('Coach is typing'), findsOneWidget);
    await waitForServer(tester);
    expect(find.bySemanticsLabel('Coach is typing'), findsNothing);
  }

  testWidgets('Dating advice opens over the tab bar and answers a quick reply with a message to send', (tester) async {
    await openDatingAdvice(tester);

    // Чат закрывает таб-бар: внизу поле ввода, над ним — с чего начать.
    expect(find.byType(MainTabBar), findsNothing);
    expect(find.text(DatingAdviceViewModel.greeting), findsOneWidget);
    expect(find.text('Describe your situation'), findsOneWidget);
    expect(find.text('They stopped replying'), findsOneWidget);

    await ask(tester, 'Should I ask them out?');

    // Вопрос остался в ленте, а быстрые ответы сменились на предложенные коучем.
    expect(find.text('Should I ask them out?'), findsOneWidget);
    expect(find.text('They stopped replying'), findsNothing);
    expect(find.textContaining('Good instinct — chats burn out when they drag.'), findsOneWidget);
    expect(find.text('Try sending'), findsOneWidget);
    expect(find.text('Make it bolder'), findsOneWidget);

    // Копирует вся карточка: VoiceOver читает «Copy» и само сообщение.
    await tester.tap(find.bySemanticsLabel(RegExp('^Copy')));
    await tester.pump();
    expect(clipboard, 'coffee thursday or a walk this weekend — which sounds more like you?');
    expect(find.text('Copied — paste it into your chat'), findsOneWidget);
    await tester.pump(const Duration(seconds: 3));

    await ask(tester, 'Give me another option');
    expect(find.text('Here’s another way to play it:'), findsOneWidget);
    expect(find.text('Try sending'), findsNWidgets(2));

    await tester.tap(find.bySemanticsLabel('Back'));
    await tester.pumpAndSettle();
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.byType(MainTabBar), findsOneWidget);
  });

  testWidgets('a typed message goes out in the chosen tone', (tester) async {
    await openDatingAdvice(tester);

    await tester.tap(find.text('✦ Auto'));
    await tester.pumpAndSettle();
    expect(find.text('Select tone'), findsOneWidget);
    await tester.tap(find.text('Flirt'));
    await tester.pumpAndSettle();
    expect(find.text('Select tone'), findsNothing);
    expect(find.text('😏 Flirt'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'She said she’s busy this week');
    await tester.pump();
    await tester.tap(find.bySemanticsLabel('Send'));
    await tester.pump();

    // Сообщение ушло в ленту, поле очистилось.
    expect(find.text('She said she’s busy this week'), findsOneWidget);
    expect(tester.widget<TextField>(find.byType(TextField)).controller!.text, isEmpty);
    await waitForServer(tester);
    expect(find.textContaining('Keep it light, show you were listening'), findsOneWidget);
  });

  testWidgets('Get the next message opens the coach with the chat attached', (tester) async {
    await openMain(tester);
    await tester.tap(find.text('Upload screenshot'));
    await waitForServer(tester);
    expect(find.byType(ChatBreakdownScreen), findsOneWidget);

    final nextMessage = find.text('Get the next message');
    await tester.scrollUntilVisible(nextMessage, 300);
    // Кнопку — в середину экрана, подальше от таб-бара.
    await Scrollable.ensureVisible(tester.element(nextMessage), alignment: 0.5);
    await tester.pumpAndSettle();
    await tester.tap(nextMessage);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byType(MainTabBar), findsNothing);
    expect(find.text('Chat attached'), findsOneWidget);
    expect(find.text('Nika, 28'), findsOneWidget);
    expect(find.text('Nika is into this — and doing most of the work.'), findsOneWidget);
    // Коуч сразу пишет о переписке, без приветствия.
    expect(find.text(DatingAdviceViewModel.greeting), findsNothing);
    expect(find.bySemanticsLabel('Coach is typing'), findsOneWidget);
    await waitForServer(tester);

    expect(find.textContaining('I read your chat. Nika is putting in most of the effort'), findsOneWidget);
    expect(find.text('It answers the last message and hands the next question back.'), findsOneWidget);
    // Третий чип за краем экрана: тестовый шрифт шире настоящего.
    expect(find.text('What if there’s no reply?', skipOffstage: false), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('Back'));
    await tester.pumpAndSettle();
    expect(find.byType(ChatBreakdownScreen), findsOneWidget);
  });

  testWidgets('+ reads a screenshot of the chat and attaches it', (tester) async {
    await openDatingAdvice(tester);
    expect(find.text('Chat attached'), findsNothing);

    await tester.tap(find.bySemanticsLabel('Attach a screenshot'));
    await tester.pump();
    await tester.pump();
    expect(find.text('Reading your chat…'), findsOneWidget);
    await waitForServer(tester);

    expect(find.text('Chat attached'), findsOneWidget);
    expect(find.text('Nika, 28'), findsOneWidget);
    expect(find.textContaining('I read your chat.'), findsOneWidget);
  });

  testWidgets('after three free answers the limit block replaces the composer', (tester) async {
    await openDatingAdvice(tester);

    await ask(tester, 'Should I ask them out?');
    await ask(tester, 'Give me another option');
    await ask(tester, 'Make it bolder');

    // Счётчик обновился после третьего ответа: вместо поля ввода — блок лимита.
    expect(find.text('You’ve used your 3 free messages'), findsOneWidget);
    expect(find.text('Go unlimited to keep the conversation going.'), findsOneWidget);
    expect(find.byType(TextField), findsNothing);
    expect(find.byType(QuickReplies), findsNothing);
    // Ответы коуча остаются: их можно перечитать и скопировать.
    expect(find.text('Try sending'), findsNWidgets(3));

    await tester.tap(find.text('Go unlimited'));
    await tester.pumpAndSettle();
    expect(find.text('No more counting'), findsOneWidget);
    await tester.tap(find.text('Not now').last);
    await tester.pumpAndSettle();
    expect(find.text('No more counting'), findsNothing);

    // «Not now» сворачивает блок в неактивное поле, а нажатие на него возвращает блок.
    await tester.tap(find.text('Not now'));
    await tester.pumpAndSettle();
    expect(find.text('You’ve used your 3 free messages'), findsNothing);
    expect(tester.widget<TextField>(find.byType(TextField)).enabled, isFalse);
    // Само поле нажатия не ловит — их ловит панель вокруг.
    await tester.tap(find.text('Describe your situation'), warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(find.text('You’ve used your 3 free messages'), findsOneWidget);
  });

  testWidgets('offline, the coach says so and waits for the connection', (tester) async {
    final connectivity = FakeConnectivity(isOnline: false);
    ConnectivityPlatform.instance = connectivity;
    await openDatingAdvice(tester);

    expect(find.text('No connection'), findsOneWidget);
    expect(find.text('Reconnect to send a message.'), findsOneWidget);
    expect(find.text('You’re offline'), findsOneWidget);
    expect(tester.widget<TextField>(find.byType(TextField)).enabled, isFalse);
    // Быстрые ответы видно, но нажатие ничего не отправляет.
    await tester.tap(find.text('They stopped replying'), warnIfMissed: false);
    await tester.pump();
    expect(find.bySemanticsLabel('Coach is typing'), findsNothing);

    connectivity.change(isOnline: true);
    await tester.pumpAndSettle();
    expect(find.text('No connection'), findsNothing);
    expect(find.text('Describe your situation'), findsOneWidget);

    await ask(tester, 'They stopped replying');
    expect(find.textContaining('It happens, and it’s usually timing'), findsOneWidget);
  });
}
