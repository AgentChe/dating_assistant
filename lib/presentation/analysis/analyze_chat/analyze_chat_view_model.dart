import 'package:dating_assistant/misc/components/view_model.dart';
import 'package:dating_assistant/misc/injector.dart';
import 'package:dating_assistant/misc/media/screenshot_picker.dart';
import 'package:dating_assistant/service/session/session_manager.dart';
import 'package:dating_assistant/service/usage/usage_manager.dart';
import 'package:flutter/foundation.dart';

sealed class AnalyzeChatAction {
  const AnalyzeChatAction();
}

/// Скриншот выбран — разбираем.
final class AnalyzeScreenshot extends AnalyzeChatAction {
  const AnalyzeScreenshot(this.screenshot);

  final Uint8List screenshot;
}

/// Бесплатные генерации на этой неделе кончились — предлагаем Cue Plus.
final class OpenPlus extends AnalyzeChatAction {
  const OpenPlus();
}

final class ImportChat extends AnalyzeChatAction {
  const ImportChat();
}

/// «Analyze your chat»: скриншот из фото или импорт всей переписки.
class AnalyzeChatViewModel extends ViewModel<AnalyzeChatAction> {
  AnalyzeChatViewModel({ScreenshotPicker? picker, SessionManager? sessionManager, UsageManager? usageManager})
    : _picker = picker ?? ScreenshotPicker(),
      _sessionManager = sessionManager ?? Injector.shared.sessionManager,
      _usageManager = usageManager ?? Injector.shared.usageManager;

  final ScreenshotPicker _picker;

  final SessionManager _sessionManager;

  final UsageManager _usageManager;

  /// null — ещё не знаем; тогда лимит проверит сервер.
  bool? _isOutOfGenerations;

  var _isPicking = false;

  /// Узнаём заранее, остались ли бесплатные генерации: проверка по нажатию задержала бы галерею.
  Future<void> load() async {
    if (await _sessionManager.hasActiveSubscriptions()) {
      _isOutOfGenerations = false;
      return;
    }
    try {
      _isOutOfGenerations = (await _usageManager.obtainUsage()).left == 0;
    } catch (error) {
      debugPrint('AnalyzeChatViewModel: cannot load the usage: $error');
    }
  }

  Future<void> chooseFromPhotos() async {
    if (_isPicking) return;
    if (_isOutOfGenerations ?? false) {
      emit(const OpenPlus());
      return;
    }

    _isPicking = true;
    try {
      final screenshot = await _picker.pick();
      if (screenshot != null) emit(AnalyzeScreenshot(screenshot));
    } catch (error) {
      debugPrint('AnalyzeChatViewModel: cannot pick the screenshot: $error');
    } finally {
      _isPicking = false;
    }
  }

  void importChat() => emit(const ImportChat());

  /// Оформили Cue Plus — лимита больше нет.
  void didSubscribe() => _isOutOfGenerations = false;

  /// Сервер ответил, что генерации кончились.
  void didReachLimit() => _isOutOfGenerations = true;
}
