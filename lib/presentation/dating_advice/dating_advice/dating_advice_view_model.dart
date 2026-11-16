import 'dart:async';

import 'package:dating_assistant/misc/components/view_model.dart';
import 'package:dating_assistant/misc/injector.dart';
import 'package:dating_assistant/misc/media/screenshot_picker.dart';
import 'package:dating_assistant/service/analysis/model/chat_breakdown.dart';
import 'package:dating_assistant/service/coach/coach_manager.dart';
import 'package:dating_assistant/service/coach/model/coach_conversation.dart';
import 'package:dating_assistant/service/coach/model/coach_reply.dart';
import 'package:dating_assistant/service/coach/model/coach_tone.dart';
import 'package:dating_assistant/service/connectivity/connectivity_manager.dart';
import 'package:dating_assistant/service/consent/ai_consent_manager.dart';
import 'package:dating_assistant/service/history/history_manager.dart';
import 'package:dating_assistant/service/usage/generation_limit.dart';
import 'package:dating_assistant/service/usage/usage_manager.dart';
import 'package:flutter/foundation.dart';

sealed class DatingAdviceAction {
  const DatingAdviceAction();
}

/// Бесплатные генерации на этой неделе кончились — предлагаем Cue Plus.
final class OpenPlus extends DatingAdviceAction {
  const OpenPlus();
}

/// «✦ Auto» — шторка «Select tone» с текущим тоном.
final class PickTone extends DatingAdviceAction {
  const PickTone(this.tone);

  final CoachTone tone;
}

/// Текст в поле ввода меняет ViewModel: очищает после отправки и возвращает, если ответа не будет.
final class ReplaceDraft extends DatingAdviceAction {
  const ReplaceDraft(this.text);

  final String text;
}

/// Сообщение в чате с коучем; [id] — ключ в ленте.
sealed class AdviceEntry {
  const AdviceEntry(this.id);

  final int id;
}

/// Сообщение коуча; с [suggestion] под ним — карточка «Try sending».
final class CoachEntry extends AdviceEntry {
  const CoachEntry(super.id, {required this.text, this.suggestion});

  final String text;

  final CoachSuggestion? suggestion;
}

/// Сообщение пользователя: своими словами или быстрым ответом.
final class UserEntry extends AdviceEntry {
  const UserEntry(super.id, {required this.text});

  final String text;
}

/// Карточка «Chat attached»: с кем переписка и главный вывод.
typedef ChatCard = ({String title, String? verdict});

/// «Dating advice» (аналог DatingAdviceViewModel): чат с коучем. Пользователь описывает ситуацию своими словами,
/// быстрым ответом или скриншотом переписки, коуч отвечает советом и готовым сообщением. Открытый из разбора
/// («Get the next message»), коуч уже знает переписку и сразу пишет, что ответить; открытый из истории —
/// продолжает разговор с того же места.
///
/// Разговор хранится только на устройстве: после каждого ответа он сохраняется в историю, а с каждым
/// сообщением уходит на сервер целиком.
class DatingAdviceViewModel extends ViewModel<DatingAdviceAction> {
  DatingAdviceViewModel({
    ChatBreakdown? breakdown,
    CoachConversation? conversation,
    CoachManager? coachManager,
    HistoryManager? historyManager,
    ConnectivityManager? connectivityManager,
    ScreenshotPicker? picker,
    GenerationLimit? limit,
    DateTime Function()? now,
  }) : _coachManager = coachManager ?? Injector.shared.coachManager,
       _historyManager = historyManager ?? Injector.shared.historyManager,
       _connectivityManager = connectivityManager ?? Injector.shared.connectivityManager,
       _picker = picker ?? ScreenshotPicker(),
       _limit = limit ?? GenerationLimit(),
       _now = now ?? DateTime.now,
       _conversation = conversation ?? CoachConversation.start(breakdown: breakdown) {
    if (conversation != null) {
      // Приветствие не часть разговора: из истории показываем только то, что в нём было.
      for (final message in conversation.messages) {
        final text = message.text;
        if (text == null) continue;
        _entries.add(
          message.isFromCoach
              ? CoachEntry(_nextId++, text: text, suggestion: message.suggestion)
              : UserEntry(_nextId++, text: text),
        );
      }
      _quickReplies = conversation.quickReplies;
    } else if (breakdown == null) {
      _entries.add(CoachEntry(_nextId++, text: greeting));
      _quickReplies = starters;
    }
    // Счётчик бесплатных генераций обновляется сам после каждого ответа.
    _limit.addListener(notifyListeners);
  }

  static const greeting = 'What’s going on? Tell me in your own words, or attach a screenshot of the chat.';

  /// С чего начать разговор, пока коуч ничего не ответил.
  static const starters = ['They stopped replying', 'Should I ask them out?', 'Help me start a chat'];

  /// Переписка приложена, а ответа о ней нет (ошибка, лимит или нет сети) — спросить ещё раз одним нажатием.
  static const askAboutChat = 'What should I send next?';

  final CoachManager _coachManager;

  final HistoryManager _historyManager;

  final ConnectivityManager _connectivityManager;

  final ScreenshotPicker _picker;

  final GenerationLimit _limit;

  final DateTime Function() _now;

  StreamSubscription<bool>? _connectivityChanges;

  /// Разговор, каким он уйдёт на сервер и в историю.
  CoachConversation _conversation;

  final _entries = <AdviceEntry>[];

  var _nextId = 0;

  var _quickReplies = const <String>[];

  var _tone = CoachTone.auto;

  var _draft = '';

  var _isReplying = false;

  var _isReadingChat = false;

  var _isPicking = false;

  var _isOffline = false;

  /// «Not now» в блоке лимита — вместо блока неактивное поле ввода.
  var _isLimitBlockHidden = false;

  List<AdviceEntry> get entries => List.unmodifiable(_entries);

  /// Коуч печатает: в конце ленты — три точки, быстрых ответов нет.
  bool get isReplying => _isReplying;

  /// Быстрые ответы над полем ввода: сначала — с чего начать, потом — что коуч предложил спросить дальше.
  List<String> get quickReplies {
    if (_isReplying) return const [];
    if (_entries.isEmpty) return const [askAboutChat];
    return _quickReplies;
  }

  CoachTone get tone => _tone;

  /// Сети нет: баннер «No connection» под шапкой, поле ввода и быстрые ответы недоступны.
  bool get isOffline => _isOffline;

  /// Бесплатные генерации на этой неделе кончились.
  bool get isLimitReached => _limit.isReached;

  /// Вместо поля ввода — «You’ve used your 3 free messages» с «Go unlimited» и «Not now».
  bool get showsLimitBlock => isLimitReached && !_isLimitBlockHidden;

  /// Бесплатных сообщений в неделю — для заголовка блока лимита.
  int get freeLimit => _limit.usage?.limit ?? GenerationLimit.freePerWeek;

  /// Поле ввода работает: есть сеть и бесплатные сообщения.
  bool get isComposerEnabled => !_isOffline && !isLimitReached;

  bool get canSend => _draft.trim().isNotEmpty && !_isReplying && isComposerEnabled;

  /// null — переписки нет. Пока сервер читает новый скриншот — «Reading your chat…».
  ChatCard? get chatCard {
    if (_isReadingChat) return (title: 'Reading your chat…', verdict: null);
    final chat = _conversation.chat;
    if (chat == null) return null;
    return (title: chat.age == null ? chat.name : '${chat.name}, ${chat.age}', verdict: chat.verdict);
  }

  /// Узнаём заранее, остались ли бесплатные генерации, и следим за сетью.
  /// Открыли из разбора — коуч сразу пишет о переписке.
  Future<void> start() async {
    unawaited(_limit.load());
    _connectivityChanges = _connectivityManager.onlineChanges.listen((isOnline) => _setOffline(!isOnline));
    await checkConnection();
    if (_conversation.isEmpty && _conversation.breakdown != null) await _ask();
  }

  /// «Retry» в баннере «No connection».
  Future<void> checkConnection() async => _setOffline(!await _connectivityManager.checkOnline());

  /// Перерисовываемся, только когда кнопка отправки меняет состояние, а не на каждую букву.
  void changeDraft(String text) {
    final wasBlank = _draft.trim().isEmpty;
    _draft = text;
    if (wasBlank != text.trim().isEmpty) notifyListeners();
  }

  Future<void> sendDraft() async {
    final text = _draft.trim();
    if (text.isNotEmpty) await _ask(text: text, isDraft: true);
  }

  Future<void> sendQuickReply(String text) => _ask(text: text);

  /// «+»: скриншот переписки из галереи — коуч прочитает его и ответит о ней.
  Future<void> attachScreenshot() async {
    if (_isPicking || _isReplying || !_canAsk()) return;

    _isPicking = true;
    Uint8List? screenshot;
    try {
      screenshot = await _picker.pick();
    } catch (error) {
      debugPrint('DatingAdviceViewModel: cannot pick the screenshot: $error');
    } finally {
      _isPicking = false;
    }
    if (screenshot != null) await _ask(screenshot: screenshot);
  }

  void openTonePicker() => emit(PickTone(_tone));

  /// Тон следующих ответов.
  void selectTone(CoachTone tone) {
    _tone = tone;
    notifyListeners();
  }

  /// «Go unlimited» в блоке лимита.
  void goUnlimited() => emit(const OpenPlus());

  /// «Not now»: блок лимита сворачивается в неактивное поле ввода.
  void hideLimitBlock() {
    _isLimitBlockHidden = true;
    notifyListeners();
  }

  /// Нажали на неактивное поле ввода: без сети ждём её, без бесплатных сообщений — снова блок лимита.
  void tapDisabledComposer() {
    if (_isOffline) {
      checkConnection();
    } else if (isLimitReached) {
      _isLimitBlockHidden = false;
      notifyListeners();
    }
  }

  /// Оформили Cue Plus — лимита больше нет.
  void didSubscribe() => _limit.didSubscribe();

  /// Отправляет сообщение и ждёт ответа. При ошибке спрашивает [tryAgain]; если ответа не будет —
  /// убирает сообщение из ленты и возвращает текст в поле. Кончились бесплатные — блок лимита.
  Future<void> _ask({String? text, Uint8List? screenshot, bool isDraft = false}) async {
    if (_isReplying || !_canAsk()) return;

    final question = text == null ? null : UserEntry(_nextId++, text: text);
    if (question != null) _entries.add(question);
    if (isDraft) _replaceDraft('');
    _isReadingChat = screenshot != null;
    _isReplying = true;
    notifyListeners();

    while (true) {
      try {
        final reply = await _coachManager.send(
          conversation: _conversation,
          text: text,
          tone: _tone,
          chatScreenshot: screenshot,
        );
        _conversation = _conversation.replied(text: text, reply: reply, at: _now());
        unawaited(_historyManager.saveConversation(_conversation));
        _entries.add(CoachEntry(_nextId++, text: reply.text, suggestion: reply.suggestion));
        _quickReplies = reply.quickReplies;
        break;
      } catch (error) {
        final isLimit = UsageManager.isGenerationLimit(error);
        // «Not now» на экране согласия — не ошибка: сообщение просто не ушло и возвращается в поле.
        final isDeclined = AiConsentManager.isDeclined(error);
        if (!isLimit && !isDeclined) {
          debugPrint('DatingAdviceViewModel: $error');
          if (await tryAgain?.call(error) ?? false) continue;
        }
        if (question != null) _entries.remove(question);
        // Пока ждали ответа, могли начать новое сообщение — его не трогаем.
        if (isDraft && text != null && _draft.trim().isEmpty) _replaceDraft(text);
        if (isLimit) {
          _limit.didReachLimit();
          _isLimitBlockHidden = false;
        }
        break;
      }
    }

    _isReadingChat = false;
    _isReplying = false;
    notifyListeners();
  }

  /// Спросить можно, когда есть сеть и бесплатные сообщения; без них показываем блок лимита.
  bool _canAsk() {
    if (_isOffline) return false;
    if (!_limit.isReached) return true;
    _isLimitBlockHidden = false;
    notifyListeners();
    return false;
  }

  void _setOffline(bool isOffline) {
    if (_isOffline == isOffline) return;
    _isOffline = isOffline;
    notifyListeners();
  }

  void _replaceDraft(String text) {
    _draft = text;
    emit(ReplaceDraft(text));
  }

  @override
  void dispose() {
    _connectivityChanges?.cancel();
    _limit.removeListener(notifyListeners);
    _limit.dispose();
    super.dispose();
  }
}
