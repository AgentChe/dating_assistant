import 'dart:async';
import 'dart:typed_data';

import 'package:dating_assistant/misc/components/fade_page_route.dart';
import 'package:dating_assistant/misc/custom_views/screen_header.dart';
import 'package:dating_assistant/misc/custom_views/try_again_sheet.dart';
import 'package:dating_assistant/presentation/analysis/analyzing/analyzing_view_model.dart';
import 'package:dating_assistant/presentation/analysis/analyzing/views/scanning_progress.dart';
import 'package:dating_assistant/presentation/analysis/analyzing/views/scanning_screenshot.dart';
import 'package:dating_assistant/service/analysis/model/chat_breakdown.dart';
import 'package:flutter/material.dart';

/// Чем закончилось сканирование; null — пользователь ушёл назад.
enum AnalyzingOutcome { finished, limitReached }

/// «Analyzing» (аналог AnalyzingViewController): скриншот сканируется, пока нейросеть разбирает переписку.
/// Открывается поверх таб-бара, на его месте — прогресс.
class AnalyzingScreen extends StatefulWidget {
  const AnalyzingScreen({super.key, required this.screenshot, required this.onFinished, this.viewModel});

  static Route<AnalyzingOutcome> route({
    required Uint8List screenshot,
    required void Function(ChatBreakdown breakdown) onFinished,
  }) => FadePageRoute(
    builder: (_) => AnalyzingScreen(screenshot: screenshot, onFinished: onFinished),
  );

  final Uint8List screenshot;

  /// Разбор готов. Вызывается до того, как сканирование закроется, — чтобы под ним уже был разбор.
  final void Function(ChatBreakdown breakdown) onFinished;

  /// Для тестов; в приложении экран создаёт ViewModel сам.
  final AnalyzingViewModel? viewModel;

  @override
  State<AnalyzingScreen> createState() => _AnalyzingScreenState();
}

class _AnalyzingScreenState extends State<AnalyzingScreen> with SingleTickerProviderStateMixin {
  late final _viewModel = widget.viewModel ?? AnalyzingViewModel(screenshot: widget.screenshot);

  late final StreamSubscription<AnalyzingAction> _actions;

  /// Сколько времени ждать ответа, никто не знает: прогресс замедляется и ждёт у 90%,
  /// а когда разбор готов, добегает до конца.
  late final _progress = AnimationController(vsync: this, duration: const Duration(seconds: 12));

  @override
  void initState() {
    super.initState();
    _actions = _viewModel.actions.listen(_handle);
    _viewModel.tryAgain = (error) => TryAgainSheet.show(context, error);
    _progress.animateTo(0.9, curve: Curves.easeOutCubic);
    _viewModel.analyze();
  }

  @override
  void dispose() {
    _actions.cancel();
    _progress.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(16, MediaQuery.paddingOf(context).top + 11, 16, 0),
            child: ScreenHeader(title: 'Analyzing', onBack: () => Navigator.of(context).pop()),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(0, 52, 0, 74),
              child: Center(
                child: AnimatedBuilder(
                  animation: _progress,
                  builder: (context, _) => ScanningScreenshot(screenshot: widget.screenshot, progress: _progress.value),
                ),
              ),
            ),
          ),
          AnimatedBuilder(
            animation: _progress,
            builder: (context, _) => ScanningProgress(progress: _progress.value),
          ),
        ],
      ),
    );
  }

  Future<void> _handle(AnalyzingAction action) async {
    switch (action) {
      case AnalysisFinished(:final breakdown):
        await _progress.animateTo(1, duration: const Duration(milliseconds: 400), curve: Curves.easeOut);
        // Пусть «100%» побудет на экране.
        await Future<void>.delayed(const Duration(milliseconds: 300));
        if (!mounted) return;
        widget.onFinished(breakdown);
        Navigator.of(context).pop(AnalyzingOutcome.finished);
      case AnalysisLimitReached():
        Navigator.of(context).pop(AnalyzingOutcome.limitReached);
      case AnalysisCancelled():
        Navigator.of(context).pop();
    }
  }
}
