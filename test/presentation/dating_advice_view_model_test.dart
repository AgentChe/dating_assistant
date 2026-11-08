import 'dart:async';

import 'package:dating_assistant/misc/media/screenshot_picker.dart';
import 'package:dating_assistant/presentation/dating_advice/dating_advice/dating_advice_view_model.dart';
import 'package:dating_assistant/service/analysis/model/chat_breakdown.dart';
import 'package:dating_assistant/service/coach/coach_manager.dart';
import 'package:dating_assistant/service/coach/model/attached_chat.dart';
import 'package:dating_assistant/service/coach/model/coach_conversation.dart';
import 'package:dating_assistant/service/coach/model/coach_reply.dart';
import 'package:dating_assistant/service/coach/model/coach_tone.dart';
import 'package:dating_assistant/service/usage/generation_limit.dart';
import 'package:dating_assistant/service/usage/usage_manager.dart';
import 'package:dating_assistant/transport/mock/routes/usage_mock_routes.dart';
import 'package:dating_assistant/transport/network_error.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_analysis.dart';
import '../fakes/fake_coach.dart';
import '../fakes/fake_managers.dart';

void main() {
  late MockCoach mock;
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
      picker: picker ?? FakeScreenshotPicker(),
      // Лимит считает тот же мок-сервер, что и ответы коуча.
      limit: GenerationLimit(
        sessionManager: FakeSessionManager(isPlus: false),
        usageManager: UsageManager(mock.transport),
        usageMediator: mock.usageMediator,
      ),
    );
    viewModel.actions.listen(actions.add);
    return viewModel;
  }

  Iterable<String> userMessages(DatingAdviceViewModel viewModel) =>
      viewModel.entries.whereType<UserEntry>().map((entry) => entry.text);

  setUp(() async {
    mock = await mockCoach();
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

  test('a typed message shows up at once, the coach types and answers with a message to send', () async {
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

    final reply = viewModel.entries.last as CoachEntry;
    expect(reply.text, startsWith('Good instinct'));
    expect(reply.suggestion?.text, 'coffee thursday or a walk this weekend — which sounds more like you?');
    expect(viewModel.isReplying, isFalse);
    expect(viewModel.quickReplies, ['Make it bolder', 'Give me another option']);
    // Поле очистилось сразу после отправки.
    expect(actions.single, isA<ReplaceDraft>().having((action) => action.text, 'text', ''));
  });

  test('quick replies continue the same conversation in the chosen tone', () async {
    final coach = FakeCoachManager([coachReply(), coachReply(text: 'Bolder it is:')]);
    final viewModel = makeViewModel(coachManager: coach);

    await viewModel.sendQuickReply('Should I ask them out?');
    viewModel.selectTone(CoachTone.flirt);
    await viewModel.sendQuickReply('Make it bolder');

    expect(coach.sent.map((message) => message.conversationId), [null, 'conversation-1']);
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

    final starting = viewModel.start();
    expect(viewModel.isReplying, isTrue);
    await starting;

    expect(
      viewModel.entries.single,
      isA<CoachEntry>().having((entry) => entry.text, 'text', startsWith('I read your chat')),
    );
    expect(viewModel.quickReplies, ['Give me another option', 'Make it bolder', 'What if there’s no reply?']);
  });

  test('the breakdown goes along until the coach has answered about it', () async {
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

    expect(coach.sent.map((message) => message.analysisId), [breakdown.id, breakdown.id, null]);
    expect(viewModel.chatCard?.title, 'Nika, 28');
  });

  test('a conversation from the history continues where it stopped', () async {
    final coach = FakeCoachManager([coachReply(conversationId: 'conversation-7')]);
    final viewModel = makeViewModel(
      coachManager: coach,
      conversation: const CoachConversation(
        id: 'conversation-7',
        chat: AttachedChat(name: 'Nika', age: 28, verdict: 'Nika is into this.'),
        messages: [
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
        quickReplies: ['Give me another option'],
      ),
    );

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
      [
        (CoachEntry, 'I read your chat.'),
        (UserEntry, 'Make it bolder'),
        (CoachEntry, 'Bolder it is:'),
      ],
    );
    expect((viewModel.entries.last as CoachEntry).suggestion?.text, 'coffee thursday?');
    expect(viewModel.chatCard, (title: 'Nika, 28', verdict: 'Nika is into this.'));
    expect(viewModel.quickReplies, ['Give me another option']);

    await viewModel.start();
    await viewModel.sendQuickReply('Give me another option');

    // Тот же разговор, и переписку второй раз не шлём.
    expect(coach.sent.single.conversationId, 'conversation-7');
    expect(coach.sent.single.analysisId, isNull);
    expect(coach.sent.single.chatScreenshot, isNull);
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

  test('without free generations Cue Plus opens and nothing is sent', () async {
    for (var index = 0; index < UsageMockRoutes.freeGenerationsPerWeek; index++) {
      await UsageMockRoutes.consumeGeneration(mock.database);
    }
    final picker = FakeScreenshotPicker();
    final viewModel = makeViewModel(picker: picker);
    await viewModel.start();
    await pumpEventQueue();

    expect(viewModel.isLimitReached, isTrue);
    viewModel.changeDraft('Hi');
    expect(viewModel.canSend, isFalse);

    await viewModel.sendQuickReply('Should I ask them out?');
    await viewModel.attachScreenshot();
    viewModel.openPlus();
    await pumpEventQueue();

    expect(actions, [isA<OpenPlus>(), isA<OpenPlus>(), isA<OpenPlus>()]);
    expect(picker.picks, 0);
    expect(viewModel.entries, hasLength(1));

    viewModel.didSubscribe();
    expect(viewModel.isLimitReached, isFalse);
    expect(viewModel.canSend, isTrue);
  });

  test('when the server says the generations are over, the message goes back and Cue Plus opens', () async {
    final viewModel = makeViewModel();
    await viewModel.start();
    await pumpEventQueue();
    // Генерации потратили на другом экране, а счётчик ещё не обновился.
    for (var index = 0; index < UsageMockRoutes.freeGenerationsPerWeek; index++) {
      await UsageMockRoutes.consumeGeneration(mock.database);
    }

    viewModel.changeDraft('Should I ask them out?');
    await viewModel.sendDraft();
    await pumpEventQueue();

    expect(userMessages(viewModel), isEmpty);
    expect(actions.whereType<ReplaceDraft>().map((action) => action.text), ['', 'Should I ask them out?']);
    expect(actions.last, isA<OpenPlus>());
    expect(viewModel.isLimitReached, isTrue);
    expect(viewModel.isReplying, isFalse);
  });
}
