import 'package:dating_assistant/misc/components/view_model.dart';
import 'package:dating_assistant/misc/injector.dart';
import 'package:dating_assistant/misc/media/screenshot_picker.dart';
import 'package:dating_assistant/service/analysis/analysis_manager.dart';
import 'package:dating_assistant/service/analysis/model/chat_breakdown.dart';
import 'package:dating_assistant/service/history/history_manager.dart';
import 'package:dating_assistant/service/session/session_manager.dart';
import 'package:dating_assistant/service/usage/generation_limit.dart';
import 'package:dating_assistant/service/usage/usage_manager.dart';
import 'package:dating_assistant/service/usage/usage_mediator.dart';
import 'package:flutter/foundation.dart';

sealed class HomeAction {
  const HomeAction();
}

/// Скриншот выбран — разбираем.
final class AnalyzeScreenshot extends HomeAction {
  const AnalyzeScreenshot(this.screenshot);

  final Uint8List screenshot;
}

/// Бесплатные генерации на этой неделе кончились — предлагаем Cue Plus.
final class OpenPlus extends HomeAction {
  const OpenPlus();
}

final class OpenDatingAdvice extends HomeAction {
  const OpenDatingAdvice();
}

final class OpenOpeningLine extends HomeAction {
  const OpenOpeningLine();
}

/// Вкладка «Main» (аналог HomeViewModel из Swift-проектов): приветствие и входы в три фичи.
/// «Upload screenshot» сразу открывает галерею — если бесплатные генерации ещё есть.
class HomeViewModel extends ViewModel<HomeAction> {
  HomeViewModel({
    DateTime Function()? now,
    ScreenshotPicker? picker,
    AnalysisManager? analysisManager,
    HistoryManager? historyManager,
    SessionManager? sessionManager,
    UsageManager? usageManager,
    UsageMediator? usageMediator,
  }) : _now = now ?? DateTime.now,
       _picker = picker ?? ScreenshotPicker(),
       _analysisManager = analysisManager ?? Injector.shared.analysisManager,
       _historyManager = historyManager ?? Injector.shared.historyManager,
       _limit = GenerationLimit(
         sessionManager: sessionManager,
         usageManager: usageManager,
         usageMediator: usageMediator,
       );

  final DateTime Function() _now;

  final ScreenshotPicker _picker;

  final AnalysisManager _analysisManager;

  final HistoryManager _historyManager;

  final GenerationLimit _limit;

  var _isPicking = false;

  /// «Good evening» — по времени на устройстве. В Figma только вечерний вариант.
  String get greeting => switch (_now().hour) {
    >= 5 && < 12 => 'Good morning',
    >= 12 && < 18 => 'Good afternoon',
    _ => 'Good evening',
  };

  /// Узнаём заранее, остались ли бесплатные генерации: проверка по нажатию задержала бы галерею.
  Future<void> loadUsage() => _limit.load();

  /// Приложение вернулось из фона: сменилось время суток, а с понедельника — бесплатный лимит.
  void refresh() {
    notifyListeners();
    loadUsage();
  }

  Future<void> uploadScreenshot() async {
    if (_isPicking) return;
    if (_limit.isReached) {
      emit(const OpenPlus());
      return;
    }

    _isPicking = true;
    try {
      final screenshot = await _picker.pick();
      if (screenshot != null) emit(AnalyzeScreenshot(screenshot));
    } catch (error) {
      debugPrint('HomeViewModel: cannot pick the screenshot: $error');
    } finally {
      _isPicking = false;
    }
  }

  /// Разбор выбранного скриншота — его ждёт сканирование.
  Future<ChatBreakdown> analyze(Uint8List screenshot) => _analysisManager.analyzeScreenshot(screenshot);

  /// Сканирование дошло до конца — разбор попадает в историю. Остановленное сканирование ничего не сохраняет.
  Future<void> keep(ChatBreakdown breakdown) => _historyManager.saveBreakdown(breakdown);

  /// Оформили Cue Plus — лимита больше нет.
  void didSubscribe() => _limit.didSubscribe();

  /// Сервер ответил, что генерации кончились.
  void didReachLimit() => _limit.didReachLimit();

  void openDatingAdvice() => emit(const OpenDatingAdvice());

  void openOpeningLine() => emit(const OpenOpeningLine());

  @override
  void dispose() {
    _limit.dispose();
    super.dispose();
  }
}
