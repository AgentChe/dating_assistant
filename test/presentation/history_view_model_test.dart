import 'package:dating_assistant/misc/extensions/history_titles.dart';
import 'package:dating_assistant/presentation/main/history/history_view_model.dart';
import 'package:dating_assistant/service/analysis/model/chat_breakdown.dart';
import 'package:dating_assistant/service/coach/model/attached_chat.dart';
import 'package:dating_assistant/service/coach/model/coach_conversation.dart';
import 'package:dating_assistant/service/coach/model/coach_reply.dart';
import 'package:dating_assistant/service/history/history_manager.dart';
import 'package:dating_assistant/service/history/history_mediator.dart';
import 'package:dating_assistant/service/history/model/history_item.dart';
import 'package:dating_assistant/service/opening_line/model/opening_line.dart';
import 'package:dating_assistant/service/usage/model/usage.dart';
import 'package:dating_assistant/service/usage/usage_mediator.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive_ce.dart';

import '../fakes/fake_analysis.dart';
import '../fakes/fake_history.dart';
import '../fakes/fake_managers.dart';

void main() {
  late ChatBreakdown breakdown;
  late Box<String> box;
  late HistoryMediator mediator;
  late HistoryManager history;
  late List<HistoryAction> actions;
  late FakeScreenshotPicker picker;

  /// 8 ноября 2026, 12:00 по местному времени.
  final now = DateTime(2026, 11, 8, 12);

  setUpAll(() async => breakdown = await exampleBreakdown());

  setUp(() async {
    box = await memoryHistoryBox();
    mediator = HistoryMediator();
    history = HistoryManager(box, mediator);
    actions = [];
    picker = FakeScreenshotPicker();
  });

  HistoryViewModel makeViewModel({Usage usage = const Usage(used: 0, limit: 3)}) {
    final viewModel = HistoryViewModel(
      now: () => now,
      historyManager: history,
      historyMediator: mediator,
      analysisManager: FakeAnalysisManager([]),
      picker: picker,
      sessionManager: FakeSessionManager(isPlus: false),
      usageManager: FakeUsageManager(usage: usage),
      usageMediator: UsageMediator(),
    )..start();
    viewModel.actions.listen(actions.add);
    return viewModel;
  }

  CoachConversation conversation({AttachedChat? chat, String suggestion = 'coffee thursday?', DateTime? at}) =>
      CoachConversation.start(at: at ?? now).replied(
        text: 'Should I ask them out?',
        reply: CoachReply(
          id: 'coach-1',
          text: 'Good instinct.',
          suggestion: CoachSuggestion(text: suggestion),
          chat: chat,
        ),
        at: at ?? now,
      );

  OpeningLineSession session(String line, {DateTime? at}) => OpeningLineSession.start(
    OpeningLine(id: 'line-1', text: line),
    at: at ?? now,
  );

  test('a new user sees the empty history', () {
    final viewModel = makeViewModel();

    expect(viewModel.isEmpty, isTrue);
  });

  test('everything saved is listed newest first, with titles and a count', () async {
    await history.saveBreakdown(breakdown, at: now.subtract(const Duration(hours: 2)));
    await history.saveConversation(conversation(at: now.subtract(const Duration(hours: 1))));
    await history.saveOpeningLines(session('perfect sunday, go'));

    final viewModel = makeViewModel();

    expect(viewModel.isEmpty, isFalse);
    expect(viewModel.items.map((item) => item.title), ['Opening line', 'Dating advice', 'Nika, 28']);
    expect(viewModel.countLabel, '3 conversations');
  });

  test('search looks through titles, names and previews', () async {
    await history.saveConversation(conversation(chat: const AttachedChat(name: 'Maya')));
    await history.saveOpeningLines(session('mountains over small talk'));
    await history.saveBreakdown(breakdown);
    final viewModel = makeViewModel();

    viewModel.search('  NIKA ');
    expect(viewModel.items.map((item) => item.title), ['Nika, 28']);
    expect(viewModel.countLabel, '1 conversation');

    viewModel.search('maya');
    expect(viewModel.items.single.kind, HistoryKind.coachConversation);

    viewModel.search('mountains');
    expect(viewModel.items.single.kind, HistoryKind.openingLine);

    viewModel.search('opening');
    expect(viewModel.items.single.kind, HistoryKind.openingLine);

    viewModel.search('tacos');
    expect(viewModel.items, isEmpty);
    expect(viewModel.countLabel, 'Nothing found');
    // Пустой результат поиска — не пустая история.
    expect(viewModel.isEmpty, isFalse);

    viewModel.search('');
    expect(viewModel.items, hasLength(3));
  });

  test('time is relative for the last week and a date after that', () {
    final viewModel = makeViewModel();
    String label(Duration age) => viewModel.timeLabel(
      HistoryItem(kind: HistoryKind.analysis, id: 'id', updatedAt: now.subtract(age), preview: ''),
    );

    expect(label(const Duration(seconds: 20)), 'now');
    expect(label(const Duration(minutes: 4)), '4 min');
    expect(label(const Duration(hours: 2, minutes: 59)), '2 h');
    expect(label(const Duration(hours: 30)), '1 day');
    expect(label(const Duration(days: 6)), '6 days');
    expect(label(const Duration(days: 27)), 'Oct 12');
    expect(label(const Duration(days: 400)), 'Oct 4, 2025');
  });

  test('a breakdown, a conversation and an opening line session open in full', () async {
    final chat = conversation(at: now.subtract(const Duration(minutes: 1)));
    final lines = session('perfect sunday, go');
    await history.saveBreakdown(breakdown, at: now.subtract(const Duration(minutes: 2)));
    await history.saveConversation(chat);
    await history.saveOpeningLines(lines);
    final viewModel = makeViewModel();
    final [lineItem, conversationItem, breakdownItem] = viewModel.items;

    viewModel
      ..open(breakdownItem)
      ..open(conversationItem)
      ..open(lineItem);
    await pumpEventQueue();

    expect(actions, [
      isA<OpenBreakdown>().having((action) => action.breakdown.nextMove, 'breakdown', breakdown.nextMove),
      isA<OpenConversation>()
          .having((action) => action.conversation.id, 'conversation', chat.id)
          .having((action) => action.conversation.messages.first.text, 'first message', 'Should I ask them out?'),
      isA<OpenOpeningLines>().having((action) => action.session.lines, 'lines', ['perfect sunday, go']),
    ]);
  });

  test('a record that is gone is not opened, the list is read again', () async {
    await history.saveBreakdown(breakdown);
    final viewModel = makeViewModel();
    final item = viewModel.items.single;
    await box.delete(item.id);

    viewModel.open(item);
    await pumpEventQueue();

    expect(actions, isEmpty);
    expect(viewModel.isEmpty, isTrue);
  });

  test('anything saved anywhere shows up at once', () async {
    final viewModel = makeViewModel();
    expect(viewModel.isEmpty, isTrue);

    await history.saveConversation(conversation());
    await pumpEventQueue();

    expect(viewModel.items.single.kind, HistoryKind.coachConversation);
  });

  test('Analyze a chat opens the gallery, and the finished breakdown lands in the history', () async {
    final viewModel = makeViewModel();
    await pumpEventQueue();

    await viewModel.analyzeChat();
    await pumpEventQueue();
    expect(picker.picks, 1);
    expect(actions.single, isA<AnalyzeScreenshot>());

    await viewModel.keep(breakdown);
    await pumpEventQueue();
    expect(viewModel.items.single.title, 'Nika, 28');
  });

  test('without free generations Analyze a chat offers Cue Plus instead of the gallery', () async {
    final viewModel = makeViewModel(usage: const Usage(used: 3, limit: 3));
    await pumpEventQueue();

    await viewModel.analyzeChat();
    await pumpEventQueue();

    expect(picker.picks, 0);
    expect(actions.single, isA<OpenPlus>());
  });

  test('a deleted record can be brought back until the toast goes away', () async {
    await history.saveBreakdown(breakdown, at: now.subtract(const Duration(minutes: 1)));
    await history.saveConversation(conversation());
    final viewModel = makeViewModel();
    final [chat, analysis] = viewModel.items;

    await viewModel.delete(chat);
    await pumpEventQueue();
    expect(viewModel.items.single.id, analysis.id);
    expect(viewModel.canUndo, isTrue);

    await viewModel.undo();
    await pumpEventQueue();
    expect(viewModel.items.map((item) => item.id), [chat.id, analysis.id]);
    expect(viewModel.canUndo, isFalse);

    // Плашка скрылась — удаление окончательное.
    await viewModel.delete(analysis);
    viewModel.forgetDeleted();
    await viewModel.undo();
    await pumpEventQueue();
    expect(viewModel.items.single.id, chat.id);
  });

  test('deleting the last record leaves the empty history, and Undo brings it back', () async {
    await history.saveBreakdown(breakdown);
    final viewModel = makeViewModel();

    await viewModel.delete(viewModel.items.single);
    await pumpEventQueue();
    expect(viewModel.isEmpty, isTrue);
    expect(viewModel.canUndo, isTrue);

    await viewModel.undo();
    await pumpEventQueue();
    expect(viewModel.items.single.title, 'Nika, 28');
  });
}
