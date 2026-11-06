import 'package:dating_assistant/misc/custom_views/glass_button.dart';
import 'package:dating_assistant/presentation/main/home/home_screen.dart';
import 'package:dating_assistant/presentation/main/home/home_view_model.dart';
import 'package:dating_assistant/presentation/main/home/views/analyze_banner.dart';
import 'package:dating_assistant/presentation/main/home/views/feature_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late HomeViewModel viewModel;
  late List<HomeAction> actions;

  Future<void> openHome(WidgetTester tester, {Size size = const Size(428, 926), double textScale = 1}) async {
    tester.view
      ..physicalSize = size * 3
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    viewModel = HomeViewModel(now: () => DateTime(2026, 11, 5, 20));
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

  testWidgets('every entry point sends its action', (tester) async {
    await openHome(tester);

    // «Upload screenshot» открывает экран — его проверяет analysis_flow_test.
    await tester.tap(find.text('Dating advice'));
    await tester.tap(find.text('Opening line'));
    await tester.tap(find.byType(GlassButton));
    await tester.pump();

    expect(actions, [HomeAction.openDatingAdvice, HomeAction.openOpeningLine, HomeAction.openMenu]);
  });

  testWidgets('fits a small iPhone with a larger system font', (tester) async {
    await openHome(tester, size: const Size(375, 667), textScale: 1.3);

    expect(tester.takeException(), isNull);
    expect(find.text('Upload screenshot'), findsOneWidget);
  });
}
