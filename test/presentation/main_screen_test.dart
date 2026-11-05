import 'package:dating_assistant/misc/injector.dart';
import 'package:dating_assistant/presentation/main/history/history_screen.dart';
import 'package:dating_assistant/presentation/main/home/home_screen.dart';
import 'package:dating_assistant/presentation/main/main/main_screen.dart';
import 'package:dating_assistant/presentation/main/main/views/main_tab_bar.dart';
import 'package:dating_assistant/presentation/main/profile/profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  // Вкладка Profile берёт менеджеры из Injector.
  setUp(() async {
    SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
    await Injector.configure();
  });

  Future<void> openMainScreen(WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: MainScreen()));
    await tester.pumpAndSettle();
  }

  Future<void> tapTab(WidgetTester tester, String title) async {
    await tester.tap(find.descendant(of: find.byType(MainTabBar), matching: find.text(title)));
    // Профиль загружает план с моков, у них задержка как у сети.
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
  }

  /// Открывает экран внутри вкладки Main — как будущий «Chat breakdown».
  Future<void> pushInsideHome(WidgetTester tester) async {
    Navigator.of(
      tester.element(find.byType(HomeScreen)),
    ).push(MaterialPageRoute<void>(builder: (_) => const Scaffold(body: Text('Chat breakdown'))));
    await tester.pumpAndSettle();
  }

  testWidgets('tabs switch screens and keep the ones already opened', (tester) async {
    await openMainScreen(tester);
    expect(find.byType(HomeScreen), findsOneWidget);
    // Остальные вкладки создаются, только когда их открыли.
    expect(find.byType(HistoryScreen, skipOffstage: false), findsNothing);
    expect(find.byType(ProfileScreen, skipOffstage: false), findsNothing);

    await tapTab(tester, 'History');
    expect(find.byType(HistoryScreen), findsOneWidget);
    expect(find.byType(HomeScreen), findsNothing);
    expect(find.byType(HomeScreen, skipOffstage: false), findsOneWidget);

    await tapTab(tester, 'Profile');
    expect(find.byType(ProfileScreen), findsOneWidget);
    expect(find.byType(HistoryScreen), findsNothing);

    await tapTab(tester, 'Main');
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.byType(ProfileScreen), findsNothing);
  });

  testWidgets('screens inside a tab open under the tab bar and survive tab switches', (tester) async {
    await openMainScreen(tester);
    await pushInsideHome(tester);
    expect(find.text('Chat breakdown'), findsOneWidget);
    expect(find.byType(MainTabBar), findsOneWidget);

    await tapTab(tester, 'History');
    expect(find.text('Chat breakdown'), findsNothing);

    await tapTab(tester, 'Main');
    expect(find.text('Chat breakdown'), findsOneWidget);

    // Повторное нажатие на открытую вкладку возвращает к её первому экрану.
    await tapTab(tester, 'Main');
    expect(find.text('Chat breakdown'), findsNothing);
    expect(find.byType(HomeScreen), findsOneWidget);
  });

  testWidgets('Android back closes the screen inside the tab, not the main screen', (tester) async {
    await openMainScreen(tester);
    await pushInsideHome(tester);

    // Системная кнопка «Назад» приходит по каналу flutter/navigation.
    await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
      SystemChannels.navigation.name,
      SystemChannels.navigation.codec.encodeMethodCall(const MethodCall('popRoute')),
      (_) {},
    );
    await tester.pumpAndSettle();

    expect(find.text('Chat breakdown'), findsNothing);
    expect(find.byType(HomeScreen), findsOneWidget);
  });

  testWidgets('screens inside tabs count the tab bar as safe area', (tester) async {
    const iPhoneInsets = FakeViewPadding(top: 47 * 3, bottom: 34 * 3);
    tester.view
      ..physicalSize = const Size(1284, 2778)
      ..devicePixelRatio = 3
      ..padding = iPhoneInsets
      ..viewPadding = iPhoneInsets;
    addTearDown(tester.view.reset);
    await openMainScreen(tester);

    // Капсула 60 и отступ 37 под ней: над полоской «домой» 34 + 3, как в Figma.
    expect(MediaQuery.paddingOf(tester.element(find.byType(HomeScreen))).bottom, 97);
    expect(tester.getRect(find.byType(MainTabBar)).bottom, 926);
    expect(tester.getSize(find.byType(MainTabBar)), const Size(428, 97));
  });
}
