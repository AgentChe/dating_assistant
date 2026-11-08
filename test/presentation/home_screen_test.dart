import 'package:dating_assistant/misc/custom_views/glass_button.dart';
import 'package:dating_assistant/presentation/main/home/home_screen.dart';
import 'package:dating_assistant/presentation/main/home/home_view_model.dart';
import 'package:dating_assistant/presentation/main/home/views/analyze_banner.dart';
import 'package:dating_assistant/presentation/main/home/views/feature_tile.dart';
import 'package:flutter/material.dart';
import 'package:dating_assistant/service/history/history_manager.dart';
import 'package:dating_assistant/service/usage/usage_mediator.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_analysis.dart';
import '../fakes/fake_history.dart';
import '../fakes/fake_managers.dart';

void main() {
  late HomeViewModel viewModel;
  late List<HomeAction> actions;
  late HistoryManager historyManager;

  setUp(() async => historyManager = await memoryHistoryManager());

  Future<void> openHome(WidgetTester tester, {Size size = const Size(428, 926), double textScale = 1}) async {
    tester.view
      ..physicalSize = size * 3
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    viewModel = HomeViewModel(
      now: () => DateTime(2026, 11, 5, 20),
      picker: FakeScreenshotPicker(),
      analysisManager: FakeAnalysisManager([]),
      historyManager: historyManager,
      sessionManager: FakeSessionManager(isPlus: false),
      usageManager: FakeUsageManager(),
      usageMediator: UsageMediator(),
    );
    actions = [];
    viewModel.actions.listen(actions.add);
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery.withClampedTextScaling(
          minScaleFactor: textScale,
          maxScaleFactor: textScale,
          child: child!,
        ),
        home: HomeScreen(viewModel: viewModel),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('shows the greeting, the chat breakdown banner and both features', (tester) async {
    await openHome(tester);

    expect(find.text('Good evening'), findsOneWidget);
    expect(find.text('What are we writing back?'), findsOneWidget);
    expect(find.text('Analyze your chat'), findsOneWidget);
    expect(find.text('Upload screenshot'), findsOneWidget);
    expect(find.text('Dating advice'), findsOneWidget);
    expect(find.text('Opening line'), findsOneWidget);
    // Размеры из Figma: баннер 396×380, плитки 192 в ширину и одной высоты.
    expect(tester.getSize(find.byType(AnalyzeBanner)), const Size(396, 380));
    final tiles = find.byType(FeatureTile);
    expect(tester.getSize(tiles.first), tester.getSize(tiles.last));
    expect(tester.getSize(tiles.first).width, 192);
  });

  testWidgets('there is no menu: the screen it opened will not exist', (tester) async {
    await openHome(tester);

    // «Upload screenshot», «Dating advice» и «Opening line» открывают экраны — это проверяют analysis_flow_test,
    // dating_advice_flow_test и opening_line_flow_test.
    expect(find.byType(GlassButton), findsNothing);
    expect(find.bySemanticsLabel('Menu'), findsNothing);
  });

  testWidgets('fits a small iPhone with a larger system font', (tester) async {
    await openHome(tester, size: const Size(375, 667), textScale: 1.3);

    expect(tester.takeException(), isNull);
    expect(find.text('Upload screenshot'), findsOneWidget);
  });
}
