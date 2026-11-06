import 'dart:async';

import 'package:dating_assistant/misc/components/view_model.dart';
import 'package:dating_assistant/misc/injector.dart';
import 'package:dating_assistant/misc/media/screenshot_picker.dart';
import 'package:dating_assistant/service/session/session_manager.dart';
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

final class OpenMenu extends HomeAction {
  const OpenMenu();
}

/// Вкладка «Main» (аналог HomeViewModel из Swift-проектов): приветствие и входы в три фичи.
/// «Upload screenshot» сразу открывает галерею — если бесплатные генерации ещё есть.
class HomeViewModel extends ViewModel<HomeAction> {
  HomeViewModel({
    DateTime Function()? now,
    ScreenshotPicker? picker,
    SessionManager? sessionManager,
    UsageManager? usageManager,
    UsageMediator? usageMediator,
  }) : _now = now ?? DateTime.now,
       _picker = picker ?? ScreenshotPicker(),
       _sessionManager = sessionManager ?? Injector.shared.sessionManager,
       _usageManager = usageManager ?? Injector.shared.usageManager {
    // Генерацию потратили — к следующему нажатию лимит уже известен.
    _usageChanges = (usageMediator ?? Injector.shared.usageMediator).changes.listen((_) => loadUsage());
  }

  final DateTime Function() _now;

  final ScreenshotPicker _picker;

  final SessionManager _sessionManager;

  final UsageManager _usageManager;

  late final StreamSubscription<void> _usageChanges;

  /// null — ещё не знаем; тогда лимит проверит сервер.
  bool? _isOutOfGenerations;

  var _isPicking = false;

  /// «Good evening» — по времени на устройстве. В Figma только вечерний вариант.
  String get greeting => switch (_now().hour) {
    >= 5 && < 12 => 'Good morning',
    >= 12 && < 18 => 'Good afternoon',
    _ => 'Good evening',
  };

  /// Узнаём заранее, остались ли бесплатные генерации: проверка по нажатию задержала бы галерею.
  Future<void> loadUsage() async {
    if (await _sessionManager.hasActiveSubscriptions()) {
      _isOutOfGenerations = false;
      return;
    }
    try {
      _isOutOfGenerations = (await _usageManager.obtainUsage()).left == 0;
    } catch (error) {
      debugPrint('HomeViewModel: cannot load the usage: $error');
    }
  }

  /// Приложение вернулось из фона: сменилось время суток, а с понедельника — бесплатный лимит.
  void refresh() {
    notifyListeners();
    loadUsage();
  }

  Future<void> uploadScreenshot() async {
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
      debugPrint('HomeViewModel: cannot pick the screenshot: $error');
    } finally {
      _isPicking = false;
    }
  }

  /// Оформили Cue Plus — лимита больше нет.
  void didSubscribe() => _isOutOfGenerations = false;

  /// Сервер ответил, что генерации кончились.
  void didReachLimit() => _isOutOfGenerations = true;

  void openMenu() => emit(const OpenMenu());

  void openDatingAdvice() => emit(const OpenDatingAdvice());

  void openOpeningLine() => emit(const OpenOpeningLine());

  @override
  void dispose() {
    _usageChanges.cancel();
    super.dispose();
  }
}
