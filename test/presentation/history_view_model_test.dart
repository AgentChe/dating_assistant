import 'package:dating_assistant/misc/extensions/history_titles.dart';
import 'package:dating_assistant/presentation/main/history/history_view_model.dart';
import 'package:dating_assistant/service/coach/model/coach_tone.dart';
import 'package:dating_assistant/service/history/history_manager.dart';
import 'package:dating_assistant/service/history/model/history_item.dart';
import 'package:dating_assistant/service/opening_line/model/opening_line.dart';
import 'package:dating_assistant/service/profile/model/spice_level.dart';
import 'package:dating_assistant/service/usage/model/usage.dart';
import 'package:dating_assistant/transport/network_error.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_analysis.dart';
import '../fakes/fake_history.dart';
import '../fakes/fake_managers.dart';

void main() {
  late MockBackend mock;
  late List<HistoryAction> actions;
  late FakeScreenshotPicker picker;

  /// 8 ноября 2026, 12:00 по местному времени.
  final now = DateTime(2026, 11, 8, 12);

  HistoryViewModel makeViewModel({HistoryManager? historyManager, Usage usage = const Usage(used: 0, limit: 3)}) {
    final viewModel = HistoryViewModel(
      now: () => now,
      historyManager: historyManager ?? mock.history,
      analysisManager: mock.analysis,
      coachManager: mock.coach,
      openingLineManager: mock.openingLines,
      picker: picker,
      sessionManager: FakeSessionManager(isPlus: false),
      usageManager: FakeUsageManager(usage: usage),
      usageMediator: mock.usageMediator,
    );
    viewModel.actions.listen(actions.add);
    return viewModel;
  }

  HistoryItem item(HistoryKind kind, {Duration age = Duration.zero, String preview = '', String? name, int? age2}) =>
      HistoryItem(
        kind: kind,
        id: '$kind-$age-$preview',
        updatedAt: now.subtract(age),
        preview: preview,
        partner: name == null ? null : (name: name, age: age2),
      );

  setUp(() async {
    mock = await mockBackend();
    actions = [];
    picker = FakeScreenshotPicker();
  });

  test('a new user sees the empty history', () async {
    final viewModel = makeViewModel();
    expect(viewModel.isLoaded, isFalse);

    viewModel.start();
    await pumpEventQueue();

    expect(viewModel.isLoaded, isTrue);
    expect(viewModel.isEmpty, isTrue);
  });

  test('everything the user made is listed newest first, with titles and a count', () async {
    await mock.analysis.analyzeScreenshot(fakeScreenshot);
    await mock.coach.send(text: 'Should I ask them out?', tone: CoachTone.auto);
    await mock.openingLines.generate(spice: SpiceLevel.warm);
    final viewModel = makeViewModel()..start();
    await pumpEventQueue();

    expect(viewModel.isEmpty, isFalse);
    expect(viewModel.items.map((item) => item.title), ['Opening line', 'Dating advice', 'Nika, 28']);
    expect(viewModel.countLabel, '3 conversations');
  });

  test('search looks through titles, names and previews', () async {
    final viewModel = makeViewModel(
      historyManager: FakeHistoryManager([
        [
          item(HistoryKind.coachConversation, preview: 'coffee thursday?', name: 'Maya'),
          item(HistoryKind.openingLine, preview: 'mountains over small talk'),
          item(HistoryKind.analysis, preview: 'Nika is into this', name: 'Nika', age2: 28),
        ],
      ]),
    )..start();
    await pumpEventQueue();

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
    String label(Duration age) => viewModel.timeLabel(item(HistoryKind.analysis, age: age));

    expect(label(const Duration(seconds: 20)), 'now');
    expect(label(const Duration(minutes: 4)), '4 min');
    expect(label(const Duration(hours: 2, minutes: 59)), '2 h');
    expect(label(const Duration(hours: 30)), '1 day');
    expect(label(const Duration(days: 6)), '6 days');
    expect(label(const Duration(days: 27)), 'Oct 12');
    expect(label(const Duration(days: 400)), 'Oct 4, 2025');
  });

  test('a breakdown, a conversation and an opening line open with everything loaded', () async {
    final breakdown = await mock.analysis.analyzeScreenshot(fakeScreenshot);
    final reply = await mock.coach.send(text: 'Should I ask them out?', tone: CoachTone.auto);
    final line = await mock.openingLines.generate(
      spice: SpiceLevel.warm,
      match: const MatchDetails(name: 'Sam'),
    );
    final viewModel = makeViewModel()..start();
    await pumpEventQueue();
    final [lineItem, conversationItem, breakdownItem] = viewModel.items;

    final opening = viewModel.open(breakdownItem);
    expect(viewModel.openingId, breakdownItem.id);
    // Пока одна запись грузится, остальные не открываются.
    await viewModel.open(lineItem);
    await opening;
    await viewModel.open(conversationItem);
    await viewModel.open(lineItem);
    await pumpEventQueue();

    expect(viewModel.openingId, isNull);
    expect(actions, [
      isA<OpenBreakdown>().having((action) => action.breakdown.id, 'breakdown', breakdown.id),
      isA<OpenConversation>()
          .having((action) => action.conversation.id, 'conversation', reply.conversationId)
          .having((action) => action.conversation.messages.first.text, 'first message', 'Should I ask them out?'),
      isA<OpenOpeningLine>()
          .having((action) => action.line.text, 'line', line.text)
          .having((action) => action.line.match?.name, 'match', 'Sam'),
    ]);
  });

  test('if a record does not load and the user gives up, nothing opens', () async {
    final viewModel = makeViewModel(
      historyManager: FakeHistoryManager([
        [item(HistoryKind.analysis, preview: 'Gone')],
      ]),
    )..tryAgain = (_) async => false;
    viewModel.start();
    await pumpEventQueue();

    await viewModel.open(viewModel.items.single);
    await pumpEventQueue();

    expect(actions, isEmpty);
    expect(viewModel.openingId, isNull);
  });

  test('a failed load shows the error until a retry succeeds', () async {
    final history = FakeHistoryManager([
      const NetworkError(NetworkErrorCode.serverNotAvailable),
      <HistoryItem>[],
    ]);
    final viewModel = makeViewModel(historyManager: history)..start();
    await pumpEventQueue();
    expect(viewModel.hasFailed, isTrue);
    expect(viewModel.isLoaded, isFalse);

    await viewModel.load();

    expect(viewModel.hasFailed, isFalse);
    expect(viewModel.isEmpty, isTrue);
  });

  test('a new generation anywhere reloads the history', () async {
    final viewModel = makeViewModel()..start();
    await pumpEventQueue();
    expect(viewModel.isEmpty, isTrue);

    await mock.coach.send(text: 'They stopped replying', tone: CoachTone.auto);
    await pumpEventQueue();

    expect(viewModel.items.single.kind, HistoryKind.coachConversation);
  });

  test('Analyze a chat opens the gallery and sends the screenshot to the analysis', () async {
    final viewModel = makeViewModel()..start();
    await pumpEventQueue();

    await viewModel.analyzeChat();
    await pumpEventQueue();

    expect(picker.picks, 1);
    expect(
      actions.single,
      isA<AnalyzeScreenshot>().having((action) => action.screenshot, 'screenshot', fakeScreenshot),
    );
  });

  test('without free generations Analyze a chat offers Cue Plus instead of the gallery', () async {
    final viewModel = makeViewModel(usage: const Usage(used: 3, limit: 3))..start();
    await pumpEventQueue();

    await viewModel.analyzeChat();
    await pumpEventQueue();

    expect(picker.picks, 0);
    expect(actions.single, isA<OpenPlus>());
  });
}
