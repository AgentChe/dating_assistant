import 'dart:async';

import 'package:dating_assistant/misc/assets.dart';
import 'package:dating_assistant/presentation/analysis/analyzing/analyzing_screen.dart';
import 'package:dating_assistant/presentation/analysis/chat_breakdown/chat_breakdown_screen.dart';
import 'package:dating_assistant/presentation/main/home/home_view_model.dart';
import 'package:dating_assistant/presentation/main/home/views/analyze_banner.dart';
import 'package:dating_assistant/presentation/main/home/views/feature_tile.dart';
import 'package:dating_assistant/presentation/main/home/views/home_header.dart';
import 'package:dating_assistant/presentation/opening_line/opening_line_source/opening_line_source_screen.dart';
import 'package:dating_assistant/service/analysis/model/chat_breakdown.dart';
import 'package:dating_assistant/presentation/splash/plus_sheet/plus_sheet.dart';
import 'package:flutter/material.dart';

/// Вкладка «Main» (аналог HomeViewController): приветствие, разбор переписки, советы коуча и первая фраза.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, this.viewModel});

  /// Для тестов; в приложении экран создаёт ViewModel сам.
  final HomeViewModel? viewModel;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final _viewModel = widget.viewModel ?? HomeViewModel();

  late final StreamSubscription<HomeAction> _actions;

  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    _actions = _viewModel.actions.listen(_handle);
    _lifecycle = AppLifecycleListener(onResume: _viewModel.refresh);
    _viewModel.loadUsage();
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    _actions.cancel();
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final padding = MediaQuery.paddingOf(context);
    return Scaffold(
      // Снизу в padding уже входит таб-бар: плитки прокручиваются над ним.
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(16, padding.top + 11, 16, padding.bottom + 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ListenableBuilder(
              listenable: _viewModel,
              builder: (context, _) => HomeHeader(greeting: _viewModel.greeting, onMenu: _viewModel.openMenu),
            ),
            const SizedBox(height: 32),
            AnalyzeBanner(onUpload: _viewModel.uploadScreenshot),
            const SizedBox(height: 20),
            // Плитки одной высоты, даже если подпись одной из них переносится на лишнюю строку.
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: FeatureTile(
                      icon: AppImages.question3d,
                      title: 'Dating advice',
                      subtitle: 'It asks about your situation',
                      onTap: _viewModel.openDatingAdvice,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FeatureTile(
                      icon: AppImages.quotes3d,
                      title: 'Opening line',
                      subtitle: 'When you match\nand go blank',
                      onTap: _viewModel.openOpeningLine,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handle(HomeAction action) async {
    switch (action) {
      case AnalyzeScreenshot(:final screenshot):
        // Разбор открывается во вкладке, пока сканирование ещё закрывает всё сверху, — и проявляется под ним.
        final navigator = Navigator.of(context);
        final outcome = await Navigator.of(context, rootNavigator: true).push(
          AnalyzingScreen.route<ChatBreakdown>(
            screenshot: screenshot,
            task: () => _viewModel.analyze(screenshot),
            onFinished: (breakdown) => navigator.push(ChatBreakdownScreen.route(breakdown, isAnimated: false)),
          ),
        );
        if (outcome == AnalyzingOutcome.limitReached && mounted) {
          _viewModel.didReachLimit();
          await _openPlus();
        }
      case OpenPlus():
        await _openPlus();
      case OpenOpeningLine():
        await Navigator.of(context).push(OpeningLineSourceScreen.route());
      // TODO: открыть чат с коучем из секции Dating advice (Figma 190:2058).
      case OpenDatingAdvice():
      // TODO: что открывает меню, в макете пока не нарисовано.
      case OpenMenu():
        debugPrint('HomeScreen: $action is not implemented yet');
    }
  }

  Future<void> _openPlus() async {
    if (await PlusSheet.present(context)) _viewModel.didSubscribe();
  }
}
