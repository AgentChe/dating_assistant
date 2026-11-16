import 'dart:async';

import 'package:dating_assistant/misc/components/view_model.dart';
import 'package:dating_assistant/misc/injector.dart';
import 'package:dating_assistant/misc/media/screenshot_picker.dart';
import 'package:dating_assistant/service/consent/ai_consent_manager.dart';
import 'package:dating_assistant/service/history/history_manager.dart';
import 'package:dating_assistant/service/opening_line/model/opening_line.dart';
import 'package:dating_assistant/service/opening_line/opening_line_manager.dart';
import 'package:dating_assistant/service/profile/model/spice_level.dart';
import 'package:dating_assistant/service/profile/profile_manager.dart';
import 'package:dating_assistant/service/usage/generation_limit.dart';
import 'package:flutter/foundation.dart';

sealed class OpeningLineSourceAction {
  const OpeningLineSourceAction();
}

/// Скриншот анкеты выбран — сканируем и пишем фразу по ней.
final class ScanBio extends OpeningLineSourceAction {
  const ScanBio(this.screenshot);

  final Uint8List screenshot;
}

/// «Type it out» — форма с подробностями о мэтче.
final class TypeItOut extends OpeningLineSourceAction {
  const TypeItOut();
}

/// «Just give me one» — фраза без подробностей.
final class GiveMeOne extends OpeningLineSourceAction {
  const GiveMeOne();
}

/// Бесплатные генерации на этой неделе кончились — предлагаем Cue Plus.
final class OpenPlus extends OpeningLineSourceAction {
  const OpenPlus();
}

/// «Opening line»: из чего писать первую фразу — анкета, подробности или ничего.
class OpeningLineSourceViewModel extends ViewModel<OpeningLineSourceAction> {
  OpeningLineSourceViewModel({
    ScreenshotPicker? picker,
    OpeningLineManager? openingLineManager,
    HistoryManager? historyManager,
    ProfileManager? profileManager,
    GenerationLimit? limit,
  }) : _picker = picker ?? ScreenshotPicker(),
       _openingLineManager = openingLineManager ?? Injector.shared.openingLineManager,
       _historyManager = historyManager ?? Injector.shared.historyManager,
       _profileManager = profileManager ?? Injector.shared.profileManager,
       _limit = limit ?? GenerationLimit();

  final ScreenshotPicker _picker;

  final OpeningLineManager _openingLineManager;

  final HistoryManager _historyManager;

  final ProfileManager _profileManager;

  final GenerationLimit _limit;

  var _isPicking = false;

  /// Узнаём заранее, остались ли бесплатные генерации.
  Future<void> load() => _limit.load();

  Future<void> uploadBio() async {
    if (_isPicking || _openPlusIfLimitReached()) return;

    _isPicking = true;
    try {
      await _openingLineManager.ensureConsent();
      final screenshot = await _picker.pick();
      if (screenshot != null) emit(ScanBio(screenshot));
    } on AiConsentDeclined {
      // «Not now»: ничего не отправлено, галерея не открывается.
    } catch (error) {
      debugPrint('OpeningLineSourceViewModel: cannot pick the screenshot: $error');
    } finally {
      _isPicking = false;
    }
  }

  void typeItOut() {
    if (!_openPlusIfLimitReached()) emit(const TypeItOut());
  }

  void giveMeOne() {
    if (!_openPlusIfLimitReached()) emit(const GiveMeOne());
  }

  /// Первая фраза по анкете — её ждёт сканирование. Острота — та, что по умолчанию в профиле.
  Future<OpeningLine> generateFromBio(Uint8List screenshot) => _openingLineManager.generate(
    spice: _profileManager.profile?.spice ?? SpiceLevel.warm,
    profileScreenshot: screenshot,
  );

  /// Сканирование дошло до конца — фраза начинает сессию в истории. Остановленное сканирование ничего не сохраняет.
  OpeningLineSession keep(OpeningLine line) {
    final session = OpeningLineSession.start(line);
    unawaited(_historyManager.saveOpeningLines(session));
    return session;
  }

  /// Оформили Cue Plus — лимита больше нет.
  void didSubscribe() => _limit.didSubscribe();

  /// Сервер ответил, что генерации кончились.
  void didReachLimit() => _limit.didReachLimit();

  bool _openPlusIfLimitReached() {
    if (!_limit.isReached) return false;
    emit(const OpenPlus());
    return true;
  }

  @override
  void dispose() {
    _limit.dispose();
    super.dispose();
  }
}
