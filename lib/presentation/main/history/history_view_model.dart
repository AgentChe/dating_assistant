import 'dart:async';

import 'package:dating_assistant/misc/components/view_model.dart';
import 'package:dating_assistant/misc/extensions/history_titles.dart';
import 'package:dating_assistant/misc/injector.dart';
import 'package:dating_assistant/misc/media/screenshot_picker.dart';
import 'package:dating_assistant/service/analysis/analysis_manager.dart';
import 'package:dating_assistant/service/analysis/model/chat_breakdown.dart';
import 'package:dating_assistant/service/coach/coach_manager.dart';
import 'package:dating_assistant/service/coach/model/coach_conversation.dart';
import 'package:dating_assistant/service/history/history_manager.dart';
import 'package:dating_assistant/service/history/model/history_item.dart';
import 'package:dating_assistant/service/opening_line/model/opening_line.dart';
import 'package:dating_assistant/service/opening_line/opening_line_manager.dart';
import 'package:dating_assistant/service/session/session_manager.dart';
import 'package:dating_assistant/service/usage/generation_limit.dart';
import 'package:dating_assistant/service/usage/usage_manager.dart';
import 'package:dating_assistant/service/usage/usage_mediator.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

sealed class HistoryAction {
  const HistoryAction();
}

/// Разбор из истории — «Chat breakdown».
final class OpenBreakdown extends HistoryAction {
  const OpenBreakdown(this.breakdown);

  final ChatBreakdown breakdown;
}

/// Разговор с коучем — Dating advice с того же места.
final class OpenConversation extends HistoryAction {
  const OpenConversation(this.conversation);

  final CoachConversation conversation;
}

/// Сессия первых фраз — последняя фраза, «Another one» продолжает её.
final class OpenOpeningLine extends HistoryAction {
  const OpenOpeningLine(this.line);

  final OpeningLine line;
}

/// «Analyze a chat»: скриншот выбран — разбираем.
final class AnalyzeScreenshot extends HistoryAction {
  const AnalyzeScreenshot(this.screenshot);

  final Uint8List screenshot;
}

/// Бесплатные генерации на этой неделе кончились — предлагаем Cue Plus.
final class OpenPlus extends HistoryAction {
  const OpenPlus();
}

/// Вкладка «History» (аналог HistoryViewModel из Swift-проектов): разборы, разговоры с коучем и первые фразы,
/// новые сверху. Историю хранит сервер и отдаёт целиком, поэтому поиск идёт по уже загруженному списку.
class HistoryViewModel extends ViewModel<HistoryAction> {
  HistoryViewModel({
    DateTime Function()? now,
    HistoryManager? historyManager,
    AnalysisManager? analysisManager,
    CoachManager? coachManager,
    OpeningLineManager? openingLineManager,
    ScreenshotPicker? picker,
    SessionManager? sessionManager,
    UsageManager? usageManager,
    UsageMediator? usageMediator,
  }) : _now = now ?? DateTime.now,
       _historyManager = historyManager ?? Injector.shared.historyManager,
       _analysisManager = analysisManager ?? Injector.shared.analysisManager,
       _coachManager = coachManager ?? Injector.shared.coachManager,
       _openingLineManager = openingLineManager ?? Injector.shared.openingLineManager,
       _picker = picker ?? ScreenshotPicker(),
       _limit = GenerationLimit(
         sessionManager: sessionManager,
         usageManager: usageManager,
         usageMediator: usageMediator,
       ) {
    // Каждая генерация — новая запись в истории или свежая в старой: список устарел, перезагружаем.
    _changes = (usageMediator ?? Injector.shared.usageMediator).changes.listen((_) => load());
  }

  final DateTime Function() _now;

  final HistoryManager _historyManager;

  final AnalysisManager _analysisManager;

  final CoachManager _coachManager;

  final OpeningLineManager _openingLineManager;

  final ScreenshotPicker _picker;

  final GenerationLimit _limit;

  late final StreamSubscription<void> _changes;

  List<HistoryItem>? _items;

  var _isLoadingHistory = false;

  /// Пока грузили, история снова изменилась — загрузим ещё раз.
  var _needsReload = false;

  var _hasFailed = false;

  var _query = '';

  String? _openingId;

  var _isPicking = false;

  /// false — история ещё ни разу не загрузилась: крутится спиннер или видна ошибка.
  bool get isLoaded => _items != null;

  /// Загрузить не вышло, а показать нечего.
  bool get hasFailed => _hasFailed && _items == null;

  /// В истории пусто — заглушка с «Analyze a chat».
  bool get isEmpty => _items?.isEmpty ?? false;

  /// Записи под поисковый запрос: по названию, имени собеседника и превью.
  List<HistoryItem> get items {
    final items = _items ?? const <HistoryItem>[];
    final query = _query.trim().toLowerCase();
    if (query.isEmpty) return items;
    return [
      for (final item in items)
        if ([item.title, item.partner?.name, item.preview].any((text) => text?.toLowerCase().contains(query) ?? false))
          item,
    ];
  }

  /// «4 conversations»; по запросу ничего нет — «Nothing found».
  String get countLabel => switch (items.length) {
    0 => 'Nothing found',
    1 => '1 conversation',
    final count => '$count conversations',
  };

  /// Запись, которая сейчас открывается: вместо времени у неё спиннер, остальные ждут.
  String? get openingId => _openingId;

  /// Узнаём заранее, остались ли бесплатные генерации, — для «Analyze a chat».
  void start() {
    _limit.load();
    load();
  }

  /// Без пагинации: сервер отдаёт всё сразу. Если список уже есть, он остаётся на экране, пока грузится новый.
  Future<void> load() async {
    if (_isLoadingHistory) {
      _needsReload = true;
      return;
    }
    _isLoadingHistory = true;
    _hasFailed = false;
    notifyListeners();
    do {
      _needsReload = false;
      try {
        _items = await _historyManager.obtainHistory();
        _hasFailed = false;
      } catch (error) {
        debugPrint('HistoryViewModel: cannot load the history: $error');
        _hasFailed = true;
      }
    } while (_needsReload);
    _isLoadingHistory = false;
    notifyListeners();
  }

  void search(String query) {
    _query = query;
    notifyListeners();
  }

  /// «4 min», «2 h», «3 days», а что старше недели — датой: «Oct 12».
  String timeLabel(HistoryItem item) {
    final now = _now();
    final age = now.difference(item.updatedAt);
    if (age.inMinutes < 1) return 'now';
    if (age.inHours < 1) return '${age.inMinutes} min';
    if (age.inDays < 1) return '${age.inHours} h';
    if (age.inDays < 7) return age.inDays == 1 ? '1 day' : '${age.inDays} days';
    final date = item.updatedAt.toLocal();
    return DateFormat(date.year == now.year ? 'MMM d' : 'MMM d, y', 'en_US').format(date);
  }

  /// Загружает запись целиком и открывает её. При ошибке спрашивает [tryAgain].
  Future<void> open(HistoryItem item) async {
    if (_openingId != null) return;
    _openingId = item.id;
    notifyListeners();

    final action = await perform<HistoryAction>(
      () async => switch (item.kind) {
        HistoryKind.analysis => OpenBreakdown(await _analysisManager.obtainAnalysis(item.id)),
        HistoryKind.coachConversation => OpenConversation(await _coachManager.obtainConversation(item.id)),
        HistoryKind.openingLine => OpenOpeningLine(await _openingLineManager.obtainSession(item.id)),
      },
    );

    _openingId = null;
    notifyListeners();
    if (action != null) emit(action);
  }

  /// «Analyze a chat» сразу открывает галерею — если бесплатные генерации ещё есть.
  Future<void> analyzeChat() async {
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
      debugPrint('HistoryViewModel: cannot pick the screenshot: $error');
    } finally {
      _isPicking = false;
    }
  }

  /// Разбор выбранного скриншота — его ждёт сканирование.
  Future<ChatBreakdown> analyze(Uint8List screenshot) => _analysisManager.analyzeScreenshot(screenshot);

  /// Оформили Cue Plus — лимита больше нет.
  void didSubscribe() => _limit.didSubscribe();

  /// Сервер ответил, что генерации кончились.
  void didReachLimit() => _limit.didReachLimit();

  @override
  void dispose() {
    _changes.cancel();
    _limit.dispose();
    super.dispose();
  }
}
