import 'dart:async';

import 'package:connectivity_plus_platform_interface/connectivity_plus_platform_interface.dart';
import 'package:dating_assistant/misc/media/screenshot_picker.dart';
import 'package:dating_assistant/presentation/dating_advice/dating_advice/dating_advice_view_model.dart';
import 'package:dating_assistant/service/analysis/model/chat_breakdown.dart';
import 'package:dating_assistant/service/coach/coach_manager.dart';
import 'package:dating_assistant/service/coach/model/attached_chat.dart';
import 'package:dating_assistant/service/coach/model/coach_conversation.dart';
import 'package:dating_assistant/service/coach/model/coach_reply.dart';
import 'package:dating_assistant/service/coach/model/coach_tone.dart';
import 'package:dating_assistant/service/connectivity/connectivity_manager.dart';
import 'package:dating_assistant/service/history/history_manager.dart';
import 'package:dating_assistant/service/usage/generation_limit.dart';
import 'package:dating_assistant/service/usage/usage_manager.dart';
import 'package:dating_assistant/transport/network_error.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_analysis.dart';
import '../fakes/fake_coach.dart';
import '../fakes/fake_connectivity.dart';
import '../fakes/fake_history.dart';
import '../fakes/fake_managers.dart';

void main() {
  late MockCoach mock;
  late HistoryManager historyManager;
  late FakeConnectivity connectivity;
  late List<DatingAdviceAction> actions;

  DatingAdviceViewModel makeViewModel({
    ChatBreakdown? breakdown,
    CoachConversation? conversation,
    CoachManager? coachManager,
    ScreenshotPicker? picker,
  }) {
    final viewModel = DatingAdviceViewModel(
      breakdown: breakdown,
      conversation: conversation,
      coachManager: coachManager ?? mock.manager,
      historyManager: historyManager,
      connectivityManager: ConnectivityManager(),
      picker: picker ?? FakeScreenshotPicker(),
      // Лимит — тот же счётчик, которым CoachManager считает ответы.
      limit: GenerationLimit(
        sessionManager: FakeSessionManager(isPlus: false),
        usageManager: mock.usageManager,
        usageMediator: mock.usageMediator,
      ),
    );
    viewModel.actions.listen(actions.add);
    return viewModel;
  }

  Iterable<String> userMessages(DatingAdviceViewModel viewModel) =>
      viewModel.entries.whereType<UserEntry>().map((entry) => entry.text);

  Future<void> useUpFreeMessages() async {
    for (var index = 0; index < UsageManager.freePerWeek; index++) {
      await mock.usageManager.recordGeneration();
    }
  }

  setUp(() async {
    mock = await mockCoach();
    historyManager = await memoryHistoryManager();
    connectivity = FakeConnectivity();
    ConnectivityPlatform.instance = connectivity;
    actions = [];
  });

  test('the chat starts with the greeting and three ways to begin', () {
    final viewModel = makeViewModel();

    expect(
      viewModel.entries.single,
      isA<CoachEntry>().having((entry) => entry.text, 'text', startsWith('What’s going on?')),
    );
    expect(viewModel.quickReplies, ['They stopped replying', 'Should I ask them out?', 'Help me start a chat']);
    expect(viewModel.tone, CoachTone.auto);
    expect(viewModel.chatCard, isNull);
    expect(viewModel.canSend, isFalse);
  });

  test('a typed message shows up at once, the coach types and answers, and the chat is saved', () async {
    final viewModel = makeViewModel();
    await viewModel.start();
    viewModel.changeDraft('  Should I ask them out?  ');
    expect(viewModel.canSend, isTrue);

    final sending = viewModel.sendDraft();
    expect(userMessages(viewModel), ['Should I ask them out?']);
    expect(viewModel.isReplying, isTrue);
    expect(viewModel.quickReplies, isEmpty);
    expect(viewModel.canSend, isFalse);
    await sending;
    await pumpEventQueue();

    final reply = viewModel.entries.last as CoachEntry;
    expect(reply.text, startsWith('Good instinct'));
    expect(reply.suggestion?.text, 'coffee thursday or a walk this weekend — which sounds more like you?');
    expect(viewModel.isReplying, isFalse);
    expect(viewModel.quickReplies, ['Make it bolder', 'Give me another option']);
    // Поле очистилось сразу после отправки.
    expect(actions.single, isA<ReplaceDraft>().having((action) => action.text, 'text', ''));
    // Разговор сохранён в историю: вопрос и ответ, без приветствия.
    final saved = historyManager.obtainConversation(historyManager.obtainHistory().single.id);
    expect(saved?.messages.map((message) => message.text?.split(' ').first), ['Should', 'Good']);
  });

  test('every message goes out with the whole conversation so far, in the chosen tone', () async {
    final coach = FakeCoachManager([coachReply(), coachReply(text: 'Bolder it is:')]);
    final viewModel = makeViewModel(coachManager: coach);

    await viewModel.sendQuickReply('Should I ask them out?');
    viewModel.selectTone(CoachTone.flirt);
    await viewModel.sendQuickReply('Make it bolder');

    final [first, second] = coach.sent;
    expect(first.conversation.messages, isEmpty);
    expect(second.conversation.id, first.conversation.id);
    expect(second.conversation.messages.map((message) => message.text), ['Should I ask them out?', 'Keep it light:']);
    expect(coach.sent.map((message) => message.tone), [CoachTone.auto, CoachTone.flirt]);
    expect(userMessages(viewModel), ['Should I ask them out?', 'Make it bolder']);
    expect((viewModel.entries.last as CoachEntry).text, 'Bolder it is:');
  });

  test('the tone picker opens with the current tone', () async {
    final viewModel = makeViewModel()..selectTone(CoachTone.intrigue);

    viewModel.openTonePicker();
    await pumpEventQueue();

    expect(actions.single, isA<PickTone>().having((action) => action.tone, 'tone', CoachTone.intrigue));
  });

  test('opened from a breakdown, the coach answers about the chat right away', () async {
    final breakdown = await mock.analysisManager.analyzeScreenshot(fakeScreenshot);
    final viewModel = makeViewModel(breakdown: breakdown);
    expect(viewModel.chatCard, (title: 'Nika, 28', verdict: 'Nika is into this — and doing most of the work.'));
    expect(viewModel.entries, isEmpty);

    // Пока ответа нет, коуч «печатает».
    final replying = <bool>[];
    viewModel.addListener(() => replying.add(viewModel.isReplying));
    await viewModel.start();

    expect(replying, contains(true));
    expect(viewModel.isReplying, isFalse);
    expect(
      viewModel.entries.single,
      isA<CoachEntry>().having((entry) => entry.text, 'text', startsWith('I read your chat')),
    );
    expect(viewModel.quickReplies, ['Give me another option', 'Make it bolder', 'What if there’s no reply?']);
  });

  test('the breakdown goes along with every message, also after a failed first answer', () async {
    final breakdown = await mock.analysisManager.analyzeScreenshot(fakeScreenshot);
    final coach = FakeCoachManager([
      const NetworkError(NetworkErrorCode.serverNotAvailable),
      coachReply(),
      coachReply(),
    ]);
    final viewModel = makeViewModel(breakdown: breakdown, coachManager: coach)..tryAgain = (_) async => false;

    await viewModel.start();
    // Ответа о переписке нет — предлагаем спросить ещё раз.
    expect(viewModel.entries, isEmpty);
    expect(viewModel.quickReplies, [DatingAdviceViewModel.askAboutChat]);

    await viewModel.sendQuickReply(DatingAdviceViewModel.askAboutChat);
    await viewModel.sendQuickReply('Make it bolder');

    expect(coach.sent.map((message) => message.conversation.breakdown?.id), [breakdown.id, breakdown.id, breakdown.id]);
    expect(viewModel.chatCard?.title, 'Nika, 28');
  });

  test('a conversation from the history continues where it stopped', () async {
    final coach = FakeCoachManager([coachReply()]);
    final conversation = CoachConversation(
      id: 'conversation-7',
      updatedAt: DateTime(2026, 11, 8),
      chat: const AttachedChat(name: 'Nika', age: 28, verdict: 'Nika is into this.'),
      messages: const [
        // Скриншот без слов — в ленте его нет.
        CoachMessage(isFromCoach: false),
        CoachMessage(
          isFromCoach: true,
          text: 'I read your chat.',
          suggestion: CoachSuggestion(text: 'which mountains?'),
        ),
        CoachMessage(isFromCoach: false, text: 'Make it bolder'),
        CoachMessage(
          isFromCoach: true,
          text: 'Bolder it is:',
          suggestion: CoachSuggestion(text: 'coffee thursday?'),
        ),
      ],
      quickReplies: const ['Give me another option'],
    );
    final viewModel = makeViewModel(coachManager: coach, conversation: conversation);

    // Приветствие не часть разговора — только его сообщения.
    expect(
      viewModel.entries.map(
        (entry) => (
          entry.runtimeType,
          switch (entry) {
            CoachEntry(:final text) || UserEntry(:final text) => text,
          },
        ),
      ),
      [(CoachEntry, 'I read your chat.'), (UserEntry, 'Make it bolder'), (CoachEntry, 'Bolder it is:')],
    );
    expect((viewModel.entries.last as CoachEntry).suggestion?.text, 'coffee thursday?');
    expect(viewModel.chatCard, (title: 'Nika, 28', verdict: 'Nika is into this.'));
    expect(viewModel.quickReplies, ['Give me another option']);

    await viewModel.start();
    await viewModel.sendQuickReply('Give me another option');
    await pumpEventQueue();

    // Тот же разговор целиком, и переписку второй раз не шлём.
    expect(coach.sent.single.conversation.id, 'conversation-7');
    expect(coach.sent.single.conversation.messages, hasLength(4));
    expect(coach.sent.single.chatScreenshot, isNull);
    expect(historyManager.obtainConversation('conversation-7')?.messages, hasLength(6));
  });

  test('a screenshot from the gallery is read and attached to the chat', () async {
    final answer = Completer<CoachReply>();
    final coach = FakeCoachManager([answer.future]);
    final viewModel = makeViewModel(coachManager: coach);

    final attaching = viewModel.attachScreenshot();
    await pumpEventQueue();
    expect(viewModel.chatCard, (title: 'Reading your chat…', verdict: null));
    expect(viewModel.isReplying, isTrue);

    answer.complete(
      coachReply(
        chat: const AttachedChat(name: 'Nika', age: 28, verdict: 'Nika is into this.'),
      ),
    );
    await attaching;

    expect(coach.sent.single.chatScreenshot, fakeScreenshot);
    expect(coach.sent.single.text, isNull);
    expect(viewModel.chatCard, (title: 'Nika, 28', verdict: 'Nika is into this.'));
    // Скриншот — не сообщение пользователя: в ленте приветствие и ответ коуча.
    expect(viewModel.entries, [isA<CoachEntry>(), isA<CoachEntry>()]);
  });

  test('a closed gallery or an unread screenshot leaves the chat as it was', () async {
    final picker = FakeScreenshotPicker()..screenshot = null;
    final coach = FakeCoachManager([const NetworkError(NetworkErrorCode.serverNotAvailable)]);
    final viewModel = makeViewModel(coachManager: coach, picker: picker)..tryAgain = (_) async => false;

    await viewModel.attachScreenshot();
    expect(coach.sent, isEmpty);

    picker.screenshot = fakeScreenshot;
    await viewModel.attachScreenshot();
    expect(coach.sent, hasLength(1));
    expect(viewModel.chatCard, isNull);
    expect(viewModel.entries, hasLength(1));
    expect(historyManager.obtainHistory(), isEmpty);
  });

  test('a message retried after an error gets its answer', () async {
    final coach = FakeCoachManager([const NetworkError(NetworkErrorCode.serverNotAvailable), coachReply()]);
    final viewModel = makeViewModel(coachManager: coach)..tryAgain = (_) async => true;

    viewModel.changeDraft('Hi');
    await viewModel.sendDraft();

    expect(coach.sent.map((message) => message.text), ['Hi', 'Hi']);
    expect(userMessages(viewModel), ['Hi']);
    expect(viewModel.entries.last, isA<CoachEntry>());
  });

  test('a message without an answer goes back to the field unless a new one is typed', () async {
    final coach = FakeCoachManager([
      const NetworkError(NetworkErrorCode.serverNotAvailable),
      const NetworkError(NetworkErrorCode.serverNotAvailable),
    ]);
    final viewModel = makeViewModel(coachManager: coach)..tryAgain = (_) async => false;

    viewModel.changeDraft('Hi');
    await viewModel.sendDraft();
    await pumpEventQueue();
    expect(userMessages(viewModel), isEmpty);
    expect(actions.whereType<ReplaceDraft>().map((action) => action.text), ['', 'Hi']);
    expect(viewModel.canSend, isTrue);

    // Пока коуч «думал», пользователь начал новое сообщение — его не затираем.
    actions.clear();
    viewModel.tryAgain = (_) async {
      viewModel.changeDraft('Actually, never mind');
      return false;
    };
    await viewModel.sendDraft();
    await pumpEventQueue();
    expect(actions.whereType<ReplaceDraft>().map((action) => action.text), ['']);
  });

  test('without free messages the limit block takes the composer’s place', () async {
    await useUpFreeMessages();
    final picker = FakeScreenshotPicker();
    final viewModel = makeViewModel(picker: picker);
    await viewModel.start();
    await pumpEventQueue();

    expect(viewModel.isLimitReached, isTrue);
    expect(viewModel.showsLimitBlock, isTrue);
    expect(viewModel.freeLimit, 3);
    viewModel.changeDraft('Hi');
    expect(viewModel.canSend, isFalse);

    // «Not now» — неактивное поле; нажатие на него и любая попытка спросить возвращают блок.
    viewModel.hideLimitBlock();
    expect(viewModel.showsLimitBlock, isFalse);
    expect(viewModel.isComposerEnabled, isFalse);
    viewModel.tapDisabledComposer();
    expect(viewModel.showsLimitBlock, isTrue);
    viewModel.hideLimitBlock();
    await viewModel.sendQuickReply('Should I ask them out?');
    await viewModel.attachScreenshot();
    expect(viewModel.showsLimitBlock, isTrue);
    expect(picker.picks, 0);
    expect(viewModel.entries, hasLength(1));

    // Шторка Cue Plus — только по «Go unlimited».
    await pumpEventQueue();
    expect(actions.whereType<OpenPlus>(), isEmpty);
    viewModel.goUnlimited();
    await pumpEventQueue();
    expect(actions.last, isA<OpenPlus>());

    viewModel.didSubscribe();
    expect(viewModel.showsLimitBlock, isFalse);
    expect(viewModel.canSend, isTrue);
  });

  test('when the server says the messages are over, the message goes back and the limit block appears', () async {
    final viewModel = makeViewModel();
    await viewModel.start();
    await pumpEventQueue();
    // Генерации потратили на другом экране, а счётчик ещё не обновился.
    await useUpFreeMessages();

    viewModel.changeDraft('Should I ask them out?');
    await viewModel.sendDraft();
    await pumpEventQueue();

    expect(userMessages(viewModel), isEmpty);
    expect(actions.whereType<ReplaceDraft>().map((action) => action.text), ['', 'Should I ask them out?']);
    expect(viewModel.showsLimitBlock, isTrue);
    expect(viewModel.isReplying, isFalse);
  });

  test('offline: the composer and quick replies are off until the connection is back', () async {
    connectivity = FakeConnectivity(isOnline: false);
    ConnectivityPlatform.instance = connectivity;
    final coach = FakeCoachManager([coachReply()]);
    final viewModel = makeViewModel(coachManager: coach);
    await viewModel.start();

    expect(viewModel.isOffline, isTrue);
    expect(viewModel.isComposerEnabled, isFalse);
    viewModel.changeDraft('Hi');
    expect(viewModel.canSend, isFalse);
    await viewModel.sendQuickReply('Should I ask them out?');
    expect(coach.sent, isEmpty);

    // «Retry», пока сети нет, ничего не меняет.
    await viewModel.checkConnection();
    expect(viewModel.isOffline, isTrue);

    connectivity.change(isOnline: true);
    await pumpEventQueue();
    expect(viewModel.isOffline, isFalse);
    expect(viewModel.canSend, isTrue);

    await viewModel.sendDraft();
    expect(coach.sent.single.text, 'Hi');

    // Сеть пропала снова — система сообщит сама.
    connectivity.change(isOnline: false);
    await pumpEventQueue();
    expect(viewModel.isOffline, isTrue);
  });

  test('opened from a breakdown without a connection, the coach waits for it', () async {
    connectivity = FakeConnectivity(isOnline: false);
    ConnectivityPlatform.instance = connectivity;
    final breakdown = await mock.analysisManager.analyzeScreenshot(fakeScreenshot);
    final coach = FakeCoachManager([coachReply()]);
    final viewModel = makeViewModel(breakdown: breakdown, coachManager: coach);

    await viewModel.start();

    expect(coach.sent, isEmpty);
    expect(viewModel.quickReplies, [DatingAdviceViewModel.askAboutChat]);
  });
}
