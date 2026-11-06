import 'package:dating_assistant/misc/components/view_model.dart';
import 'package:dating_assistant/misc/injector.dart';
import 'package:dating_assistant/service/opening_line/model/opening_line.dart';
import 'package:dating_assistant/service/opening_line/opening_line_manager.dart';
import 'package:dating_assistant/service/profile/model/spice_level.dart';
import 'package:dating_assistant/service/profile/profile_manager.dart';
import 'package:dating_assistant/service/usage/generation_limit.dart';
import 'package:dating_assistant/service/usage/usage_manager.dart';
import 'package:flutter/foundation.dart';

enum OpeningLineAction { openPlus }

/// Первая фраза для мэтча: острота и «Another one».
class OpeningLineViewModel extends ViewModel<OpeningLineAction> {
  OpeningLineViewModel({
    MatchDetails? match,
    OpeningLine? firstLine,
    OpeningLineManager? openingLineManager,
    ProfileManager? profileManager,
    GenerationLimit? limit,
  }) : _match = match ?? firstLine?.match,
       _line = firstLine,
       _openingLineManager = openingLineManager ?? Injector.shared.openingLineManager,
       _limit = limit ?? GenerationLimit() {
    _spice = (profileManager ?? Injector.shared.profileManager).profile?.spice ?? SpiceLevel.warm;
    if (firstLine != null) _previousLines.add(firstLine.text);
    // Счётчик бесплатных генераций обновляется сам после каждой фразы.
    _limit.addListener(notifyListeners);
  }

  final OpeningLineManager _openingLineManager;

  final GenerationLimit _limit;

  final _previousLines = <String>[];

  MatchDetails? _match;

  OpeningLine? _line;

  late SpiceLevel _spice;

  var _isGenerating = false;

  /// null — фразы ещё нет.
  OpeningLine? get line => _line;

  /// Острота следующей фразы; сначала — та, что по умолчанию в профиле.
  SpiceLevel get spice => _spice;

  bool get isGenerating => _isGenerating;

  /// «1 of 3 free generations left»; с Cue Plus лимита нет — «Written in your voice».
  String get caption {
    final usage = _limit.usage;
    return usage == null ? 'Written in your voice' : '${usage.left} of ${usage.limit} free generations left';
  }

  /// Без готовой фразы (её не написало сканирование анкеты) — сразу пишем первую.
  Future<void> start() async {
    _limit.load();
    if (_line == null) await generate();
  }

  void selectSpice(SpiceLevel spice) {
    _spice = spice;
    notifyListeners();
  }

  /// «Another one». При ошибке спрашивает [tryAgain]; кончились бесплатные — Cue Plus.
  Future<void> generate() async {
    if (_isGenerating) return;
    if (_limit.isReached) {
      emit(OpeningLineAction.openPlus);
      return;
    }

    _isGenerating = true;
    notifyListeners();
    while (true) {
      try {
        final line = await _openingLineManager.generate(spice: _spice, match: _match, previousLines: _previousLines);
        _line = line;
        _previousLines.add(line.text);
        _match ??= line.match;
        break;
      } catch (error) {
        if (UsageManager.isGenerationLimit(error)) {
          _limit.didReachLimit();
          emit(OpeningLineAction.openPlus);
          break;
        }
        debugPrint('OpeningLineViewModel: $error');
        if (!(await tryAgain?.call(error) ?? false)) break;
      }
    }
    _isGenerating = false;
    notifyListeners();
  }

  /// Оформили Cue Plus — лимита больше нет.
  void didSubscribe() => _limit.didSubscribe();

  @override
  void dispose() {
    _limit.removeListener(notifyListeners);
    _limit.dispose();
    super.dispose();
  }
}
