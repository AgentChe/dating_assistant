import 'dart:async';
import 'dart:typed_data';

import 'package:dating_assistant/misc/assets.dart';
import 'package:dating_assistant/misc/components/fade_page_route.dart';
import 'package:dating_assistant/misc/custom_views/app_dialog.dart';
import 'package:dating_assistant/misc/custom_views/screen_header.dart';
import 'package:dating_assistant/misc/custom_views/try_again_sheet.dart';
import 'package:dating_assistant/presentation/analysis/analyzing/analyzing_view_model.dart';
import 'package:dating_assistant/presentation/analysis/analyzing/views/scanning_progress.dart';
import 'package:dating_assistant/presentation/analysis/analyzing/views/scanning_screenshot.dart';
import 'package:flutter/material.dart';

/// Чем закончилось сканирование; null — пользователь ушёл назад.
enum AnalyzingOutcome { finished, limitReached }

/// «Analyzing» (аналог AnalyzingViewController): скриншот сканируется, пока нейросеть с ним работает —
/// разбирает переписку или читает анкету для первой фразы. Открывается поверх таб-бара, на его месте — прогресс.
class AnalyzingScreen<T> extends StatefulWidget {
  const AnalyzingScreen({
    super.key,
    required this.screenshot,
    required this.task,
    required this.onFinished,
  });

  static Route<AnalyzingOutcome> route<T>({
    required Uint8List screenshot,
    required Future<T> Function() task,
    required void Function(T result) onFinished,
  }) => FadePageRoute(
    builder: (_) => AnalyzingScreen<T>(screenshot: screenshot, task: task, onFinished: onFinished),
  );

  final Uint8List screenshot;

  /// Запрос к нейросети по скриншоту.
  final Future<T> Function() task;

  /// Ответ готов. Вызывается до того, как сканирование закроется, — чтобы под ним уже был следующий экран.
  final void Function(T result) onFinished;

  @override
  State<AnalyzingScreen<T>> createState() => _AnalyzingScreenState<T>();
}

class _AnalyzingScreenState<T> extends State<AnalyzingScreen<T>> with SingleTickerProviderStateMixin {
  late final _viewModel = AnalyzingViewModel<T>(task: widget.task);

  late final StreamSubscription<AnalyzingAction<T>> _actions;

  /// Сколько времени ждать ответа, никто не знает: прогресс замедляется и ждёт у 90%,
  /// а когда ответ готов, добегает до конца.
  late final _progress = AnimationController(vsync: this, duration: const Duration(seconds: 12));

  /// Открытое «Stop analyzing?»: его ответа ждёт и «назад», и пришедший тем временем результат.
  Future<bool>? _stopQuestion;

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
    // «Назад» — кнопкой в шапке или системным жестом — сначала спрашивает, остановить ли сканирование.
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _askToStop();
      },
      child: _content(context),
    );
  }

  Widget _content(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(16, MediaQuery.paddingOf(context).top + 11, 16, 0),
            child: ScreenHeader(title: 'Analyzing', onBack: _askToStop),
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

  /// «Stop» закрывает сканирование: результат, даже если придёт, никуда не попадёт.
  Future<void> _askToStop() async {
    if (_stopQuestion != null) return;
    final question = AppDialog.show(
      context,
      icon: AppIcons.info,
      title: 'Stop analyzing?',
      message: 'Your screenshot won’t be saved.',
      confirmTitle: 'Stop',
      cancelTitle: 'Keep going',
    );
    _stopQuestion = question;
    final stop = await question;
    _stopQuestion = null;
    if (stop && mounted) Navigator.of(context).pop();
  }

  Future<void> _handle(AnalyzingAction<T> action) async {
    // Пока открыт «Stop analyzing?», результат ждёт решения: после «Stop» его просто выбрасываем.
    final question = _stopQuestion;
    if (question != null && await question) return;
    if (!mounted) return;
    switch (action) {
      case AnalysisFinished(:final result):
        await _progress.animateTo(1, duration: const Duration(milliseconds: 400), curve: Curves.easeOut);
        // Пусть «100%» побудет на экране.
        await Future<void>.delayed(const Duration(milliseconds: 300));
        if (!mounted) return;
        widget.onFinished(result);
        Navigator.of(context).pop(AnalyzingOutcome.finished);
      case AnalysisLimitReached():
        Navigator.of(context).pop(AnalyzingOutcome.limitReached);
      case AnalysisCancelled():
        Navigator.of(context).pop();
    }
  }
}
