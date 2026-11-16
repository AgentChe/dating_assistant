import 'dart:async';

import 'package:dating_assistant/misc/components/view_model.dart';
import 'package:dating_assistant/misc/injector.dart';
import 'package:dating_assistant/service/consent/ai_consent_manager.dart';
import 'package:dating_assistant/service/history/history_manager.dart';
import 'package:dating_assistant/service/opening_line/model/opening_line.dart';
import 'package:dating_assistant/service/opening_line/opening_line_manager.dart';
import 'package:dating_assistant/service/profile/model/spice_level.dart';
import 'package:dating_assistant/service/profile/profile_manager.dart';
import 'package:dating_assistant/service/usage/generation_limit.dart';
import 'package:dating_assistant/service/usage/usage_manager.dart';
import 'package:flutter/foundation.dart';

enum OpeningLineAction { openPlus, close }

/// Первая фраза для мэтча: острота и «Another one». Фразы для одного мэтча — сессия: она живёт в истории
/// на устройстве, а уже предложенные фразы уходят на сервер, чтобы он не повторялся.
class OpeningLineViewModel extends ViewModel<OpeningLineAction> {
  OpeningLineViewModel({
    MatchDetails? match,
    OpeningLineSession? session,
    OpeningLineManager? openingLineManager,
    HistoryManager? historyManager,
    ProfileManager? profileManager,
    GenerationLimit? limit,
    DateTime Function()? now,
  }) : _match = match ?? session?.match,
       _session = session,
       _line = session?.latest,
       _openingLineManager = openingLineManager ?? Injector.shared.openingLineManager,
       _historyManager = historyManager ?? Injector.shared.historyManager,
       _limit = limit ?? GenerationLimit(),
       _now = now ?? DateTime.now {
    _spice = (profileManager ?? Injector.shared.profileManager).profile?.spice ?? SpiceLevel.warm;
    if (session != null) _previousLines.addAll(session.lines);
    // Счётчик бесплатных генераций обновляется сам после каждой фразы.
    _limit.addListener(notifyListeners);
  }

  final OpeningLineManager _openingLineManager;

  final HistoryManager _historyManager;

  final GenerationLimit _limit;

  final DateTime Function() _now;

  final _previousLines = <String>[];

  MatchDetails? _match;

  /// Сессия в истории; null — фраз ещё не было.
  OpeningLineSession? _session;

  OpeningLine? _line;

  late SpiceLevel _spice;

  var _isGenerating = false;

  var _hasFailed = false;

  /// null — фразы ещё нет.
  OpeningLine? get line => _line;

  /// Острота следующей фразы; сначала — та, что по умолчанию в профиле.
  SpiceLevel get spice => _spice;

  bool get isGenerating => _isGenerating;

  /// Бесплатные генерации кончились: баннер лимита, фраза и острота неактивны, вместо «Another one» — «Go unlimited».
  bool get isLimitReached => _limit.isReached;

  /// Фразу написать не вышло: баннер ошибки, вместо «Another one» — «Try again».
  bool get hasFailed => _hasFailed && !isLimitReached;

  /// Бесплатных генераций в неделю — для «You’ve used your 3 free generations».
  int get freeLimit => _limit.usage?.limit ?? GenerationLimit.freePerWeek;

  /// «1 of 3 free generations left»; с Cue Plus лимита нет — «Written in your voice».
  String get caption {
    final usage = _limit.usage;
    return usage == null ? 'Written in your voice' : '${usage.left} of ${usage.limit} free generations left';
  }

  /// Без готовой фразы (сессию не открыли из истории или сканирования анкеты) — сразу пишем первую.
  Future<void> start() async {
    _limit.load();
    if (_line == null) await generate();
  }

  void selectSpice(SpiceLevel spice) {
    _spice = spice;
    notifyListeners();
  }

  /// «Another one» и «Try again». Кончились бесплатные — экран показывает лимит, ошибка — баннер с «Retry».
  Future<void> generate() async {
    if (_isGenerating || _limit.isReached) return;

    _isGenerating = true;
    _hasFailed = false;
    notifyListeners();
    try {
      final line = await _openingLineManager.generate(spice: _spice, match: _match, previousLines: _previousLines);
      final session = _session?.adding(line, at: _now()) ?? OpeningLineSession.start(line, match: _match, at: _now());
      _session = session;
      _line = line;
      _previousLines.add(line.text);
      _match ??= line.match;
      unawaited(_historyManager.saveOpeningLines(session));
    } catch (error) {
      if (UsageManager.isGenerationLimit(error)) {
        _limit.didReachLimit();
      } else if (AiConsentManager.isDeclined(error)) {
        // «Not now»: фраза не написана. Первой фразы нет — показывать нечего, экран закрывается.
        if (_line == null) emit(OpeningLineAction.close);
      } else {
        debugPrint('OpeningLineViewModel: $error');
        _hasFailed = true;
      }
    }
    _isGenerating = false;
    notifyListeners();
  }

  /// «Go unlimited» вместо «Another one».
  void goUnlimited() => emit(OpeningLineAction.openPlus);

  /// Оформили Cue Plus — лимита больше нет.
  void didSubscribe() => _limit.didSubscribe();

  @override
  void dispose() {
    _limit.removeListener(notifyListeners);
    _limit.dispose();
    super.dispose();
  }
}
