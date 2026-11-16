import 'dart:async';

import 'package:dating_assistant/misc/components/view_model.dart';
import 'package:dating_assistant/misc/extensions/history_titles.dart';
import 'package:dating_assistant/misc/injector.dart';
import 'package:dating_assistant/misc/media/screenshot_picker.dart';
import 'package:dating_assistant/service/analysis/analysis_manager.dart';
import 'package:dating_assistant/service/analysis/model/chat_breakdown.dart';
import 'package:dating_assistant/service/consent/ai_consent_manager.dart';
import 'package:dating_assistant/service/coach/model/coach_conversation.dart';
import 'package:dating_assistant/service/history/history_manager.dart';
import 'package:dating_assistant/service/history/history_mediator.dart';
import 'package:dating_assistant/service/history/model/history_item.dart';
import 'package:dating_assistant/service/opening_line/model/opening_line.dart';
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

/// Фразы для мэтча — последняя фраза, «Another one» продолжает сессию.
final class OpenOpeningLines extends HistoryAction {
  const OpenOpeningLines(this.session);

  final OpeningLineSession session;
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

/// Вкладка «History» (аналог HistoryViewModel из Swift-проектов): разборы, разговоры с коучем и фразы,
/// новые сверху. История хранится только на устройстве и читается сразу, поиск — по всему списку.
class HistoryViewModel extends ViewModel<HistoryAction> {
  HistoryViewModel({
    DateTime Function()? now,
    HistoryManager? historyManager,
    HistoryMediator? historyMediator,
    AnalysisManager? analysisManager,
    ScreenshotPicker? picker,
    SessionManager? sessionManager,
    UsageManager? usageManager,
    UsageMediator? usageMediator,
  }) : _now = now ?? DateTime.now,
       _historyManager = historyManager ?? Injector.shared.historyManager,
       _analysisManager = analysisManager ?? Injector.shared.analysisManager,
       _picker = picker ?? ScreenshotPicker(),
       _limit = GenerationLimit(
         sessionManager: sessionManager,
         usageManager: usageManager,
         usageMediator: usageMediator,
       ) {
    // Что-то сохранили — на этой вкладке или на другой: список устарел.
    _changes = (historyMediator ?? Injector.shared.historyMediator).changes.listen((_) => load());
  }

  final DateTime Function() _now;

  final HistoryManager _historyManager;

  final AnalysisManager _analysisManager;

  final ScreenshotPicker _picker;

  final GenerationLimit _limit;

  late final StreamSubscription<void> _changes;

  var _items = const <HistoryItem>[];

  var _query = '';

  var _isPicking = false;

  /// Только что удалённая запись: пока она есть, плашка «Conversation deleted» предлагает «Undo».
  DeletedHistoryRecord? _deleted;

  /// В истории пусто — заглушка с «Analyze a chat».
  bool get isEmpty => _items.isEmpty;

  /// Записи под поисковый запрос: по названию, имени собеседника и превью.
  List<HistoryItem> get items {
    final query = _query.trim().toLowerCase();
    if (query.isEmpty) return _items;
    return [
      for (final item in _items)
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

  /// Узнаём заранее, остались ли бесплатные генерации, — для «Analyze a chat».
  void start() {
    _limit.load();
    load();
  }

  void load() {
    _items = _historyManager.obtainHistory();
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

  /// Открывает запись целиком. Если её уже не прочитать — просто обновляем список.
  void open(HistoryItem item) {
    final action = switch (item.kind) {
      HistoryKind.analysis => switch (_historyManager.obtainBreakdown(item.id)) {
        final breakdown? => OpenBreakdown(breakdown),
        null => null,
      },
      HistoryKind.coachConversation => switch (_historyManager.obtainConversation(item.id)) {
        final conversation? => OpenConversation(conversation),
        null => null,
      },
      HistoryKind.openingLine => switch (_historyManager.obtainOpeningLines(item.id)) {
        final session? => OpenOpeningLines(session),
        null => null,
      },
    };
    if (action == null) {
      load();
    } else {
      emit(action);
    }
  }

  /// Удалённую запись ещё можно вернуть — видна плашка с «Undo».
  bool get canUndo => _deleted != null;

  /// Пользователь подтвердил удаление. Список обновится сам — удаление сообщает HistoryMediator.
  Future<void> delete(HistoryItem item) async {
    _deleted = await _historyManager.delete(item.id);
    notifyListeners();
  }

  /// «Undo» в плашке: запись возвращается на своё место.
  Future<void> undo() async {
    final deleted = _deleted;
    if (deleted == null) return;
    _deleted = null;
    notifyListeners();
    await _historyManager.restore(deleted);
  }

  /// Плашка скрылась — вернуть запись уже нельзя.
  void forgetDeleted() {
    if (_deleted == null) return;
    _deleted = null;
    notifyListeners();
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
      await _analysisManager.ensureConsent();
      final screenshot = await _picker.pick();
      if (screenshot != null) emit(AnalyzeScreenshot(screenshot));
    } on AiConsentDeclined {
      // «Not now»: ничего не отправлено, галерея не открывается.
    } catch (error) {
      debugPrint('HistoryViewModel: cannot pick the screenshot: $error');
    } finally {
      _isPicking = false;
    }
  }

  /// Разбор выбранного скриншота — его ждёт сканирование.
  Future<ChatBreakdown> analyze(Uint8List screenshot) => _analysisManager.analyzeScreenshot(screenshot);

  /// Сканирование дошло до конца — разбор попадает в историю.
  Future<void> keep(ChatBreakdown breakdown) => _historyManager.saveBreakdown(breakdown);

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
