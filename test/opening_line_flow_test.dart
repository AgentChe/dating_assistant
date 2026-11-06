import 'package:dating_assistant/misc/injector.dart';
import 'package:dating_assistant/presentation/main/main/main_screen.dart';
import 'package:dating_assistant/presentation/main/main/views/main_tab_bar.dart';
import 'package:dating_assistant/presentation/opening_line/match_details/match_details_screen.dart';
import 'package:dating_assistant/presentation/opening_line/opening_line/opening_line_screen.dart';
import 'package:dating_assistant/presentation/opening_line/opening_line_source/opening_line_source_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';
import 'package:in_app_purchase_platform_interface/in_app_purchase_platform_interface.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import 'fakes/fake_analysis.dart';
import 'fakes/fake_store.dart';

/// Галерея, в которой пользователь сразу выбирает скриншот анкеты.
class _FakeImagePicker extends ImagePickerPlatform {
  @override
  Future<XFile?> getImageFromSource({
    required ImageSource source,
    ImagePickerOptions options = const ImagePickerOptions(),
  }) async => XFile.fromData(fakeScreenshot, name: 'bio.png');
}

void main() {
  late String? clipboard;

  setUp(() async {
    SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
    InAppPurchasePlatform.instance = FakeStore(isStoreAvailable: false);
    ImagePickerPlatform.instance = _FakeImagePicker();
    await Injector.configure();
    clipboard = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (
        call,
      ) async {
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

  Future<void> openOpeningLine(WidgetTester tester) async {
    tester.view
      ..physicalSize = const Size(1284, 2778)
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const MaterialApp(home: MainScreen()));
    await waitForServer(tester);
    await tester.tap(find.text('Opening line'));
    await waitForServer(tester);
    expect(find.byType(OpeningLineSourceScreen), findsOneWidget);
  }

  testWidgets('Just give me one writes a line, copies it and writes another', (tester) async {
    await openOpeningLine(tester);

    await tester.tap(find.text('Just give me one'));
    await waitForServer(tester);

    expect(find.byType(OpeningLineScreen), findsOneWidget);
    expect(find.byType(MainTabBar), findsOneWidget);
    expect(find.text('2 of 3 free generations left'), findsOneWidget);
    final first = (tester.widget<Text>(
      find.descendant(of: find.byType(OpeningLineScreen), matching: find.byType(Text)).at(1),
    )).data;

    await tester.tap(find.bySemanticsLabel('Copy'));
    await tester.pump();
    expect(clipboard, first);
    expect(find.text('Copied — paste it into your chat'), findsOneWidget);
    await tester.pump(const Duration(seconds: 3));

    await tester.tap(find.text('Another one'));
    await waitForServer(tester);
    expect(find.text(first!), findsNothing);
    expect(find.text('1 of 3 free generations left'), findsOneWidget);
  });

  testWidgets('Type it out sends the details and shows the line under the form', (tester) async {
    await openOpeningLine(tester);

    await tester.tap(find.text('Type it out'));
    await tester.pumpAndSettle();
    expect(find.byType(MatchDetailsScreen), findsOneWidget);
    // Форма закрывает таб-бар, внизу — «Continue».
    expect(find.byType(MainTabBar), findsNothing);

    await tester.enterText(find.byType(TextField).at(0), 'Sam');
    await tester.enterText(find.byType(TextField).at(3), 'Climbing, bad puns');
    await tester.pump();
    await tester.tap(find.text('Continue'));
    await waitForServer(tester);

    expect(find.byType(MatchDetailsScreen), findsNothing);
    expect(find.byType(OpeningLineScreen), findsOneWidget);
    expect(find.textContaining('climbing'), findsOneWidget);
  });

  testWidgets('Upload their bio scans the profile and writes a line about it', (tester) async {
    await openOpeningLine(tester);

    await tester.tap(find.text('Upload their bio'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Scanning'), findsOneWidget);
    await waitForServer(tester);

    expect(find.byType(OpeningLineScreen), findsOneWidget);
    expect(find.text('fair. what would have to happen down here for you to come back?'), findsOneWidget);

    // Назад — к выбору способа.
    await tester.tap(find.bySemanticsLabel('Back'));
    await tester.pumpAndSettle();
    expect(find.byType(OpeningLineSourceScreen), findsOneWidget);
  });
}
