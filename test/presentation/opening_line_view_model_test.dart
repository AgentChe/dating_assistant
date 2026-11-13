import 'package:dating_assistant/presentation/opening_line/opening_line/opening_line_view_model.dart';
import 'package:dating_assistant/service/history/history_manager.dart';
import 'package:dating_assistant/service/history/model/history_item.dart';
import 'package:dating_assistant/service/opening_line/model/opening_line.dart';
import 'package:dating_assistant/service/opening_line/opening_line_manager.dart';
import 'package:dating_assistant/service/profile/model/spice_level.dart';
import 'package:dating_assistant/service/usage/generation_limit.dart';
import 'package:dating_assistant/transport/network_error.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_analysis.dart';
import '../fakes/fake_history.dart';
import '../fakes/fake_managers.dart';
import '../fakes/fake_opening_line.dart';

/// Фразы без сервера: по очереди отдаёт заданное в тесте и запоминает, какие фразы ушли как уже предложенные.
class _FakeOpeningLineManager implements OpeningLineManager {
  _FakeOpeningLineManager(this.results);

  final List<Object> results;

  final previousLines = <List<String>>[];

  @override
  Future<OpeningLine> generate({
    required SpiceLevel spice,
    MatchDetails? match,
    dynamic profileScreenshot,
    List<String> previousLines = const [],
  }) async {
    this.previousLines.add([...previousLines]);
    final result = results.removeAt(0);
    if (result is OpeningLine) return result;
    throw result;
  }
}

void main() {
  late MockOpeningLines mock;
  late HistoryManager historyManager;
  late List<OpeningLineAction> actions;

  OpeningLineViewModel makeViewModel({
    MatchDetails? match,
    OpeningLineSession? session,
    OpeningLineManager? openingLineManager,
  }) {
    final viewModel = OpeningLineViewModel(
      match: match,
      session: session,
      openingLineManager: openingLineManager ?? mock.manager,
      historyManager: historyManager,
      profileManager: mock.profileManager,
      // Лимит — тот же счётчик, которым OpeningLineManager считает фразы.
      limit: GenerationLimit(
        sessionManager: FakeSessionManager(isPlus: false),
        usageManager: mock.usageManager,
        usageMediator: mock.usageMediator,
      ),
    );
    viewModel.actions.listen(actions.add);
    return viewModel;
  }

  setUp(() async {
    mock = await mockOpeningLines();
    historyManager = await memoryHistoryManager();
    actions = [];
  });

  test('without a ready line the screen writes the first one in the profile spice and saves it', () async {
    final viewModel = makeViewModel();
    expect(viewModel.spice, SpiceLevel.warm);

    await viewModel.start();
    await pumpEventQueue();

    expect(viewModel.line?.text, isNotEmpty);
    expect(viewModel.isGenerating, isFalse);
    expect(viewModel.caption, '2 of 3 free generations left');
    final saved = historyManager.obtainHistory().single;
    expect((saved.kind, saved.preview), (HistoryKind.openingLine, viewModel.line?.text));
  });

  test('a line from the bio scan is shown as is, and the next one uses what the server read', () async {
    final first = await mock.manager.generate(spice: SpiceLevel.warm, profileScreenshot: fakeScreenshot);
    final viewModel = makeViewModel(session: OpeningLineSession.start(first));

    await viewModel.start();
    expect(viewModel.line?.text, first.text);

    viewModel.selectSpice(SpiceLevel.spicy);
    await viewModel.generate();

    expect(viewModel.line?.text, isNot(first.text));
    // Острота из ползунка, а имя и интересы — из прочитанной анкеты.
    expect(viewModel.line?.text, anyOf(contains('Nika'), contains('into mountains')));
  });

  test('Another one never repeats a line and keeps one record in the history', () async {
    final viewModel = makeViewModel(match: const MatchDetails(name: 'Sam'));
    await viewModel.start();
    final first = viewModel.line!.text;

    await viewModel.generate();

    expect(viewModel.line!.text, isNot(first));
    final reopened = historyManager.obtainOpeningLines(historyManager.obtainHistory().single.id);
    expect(reopened?.lines, [first, viewModel.line!.text]);
    expect(reopened?.match?.name, 'Sam');
  });

  test('a session from the history goes on without repeating any of its lines', () async {
    final lines = _FakeOpeningLineManager([const OpeningLine(id: 'line-3', text: 'third')]);
    final session =
        OpeningLineSession.start(
          const OpeningLine(id: 'line-1', text: 'first'),
          match: const MatchDetails(name: 'Sam'),
        ).adding(
          const OpeningLine(id: 'line-2', text: 'second'),
          at: DateTime.now(),
        );
    final viewModel = makeViewModel(session: session, openingLineManager: lines);

    await viewModel.start();
    expect(viewModel.line?.text, 'second');
    await viewModel.generate();

    expect(lines.previousLines.single, ['first', 'second']);
    expect(historyManager.obtainOpeningLines(session.id)?.lines, ['first', 'second', 'third']);
  });

  test('without free generations the screen shows the limit and Go unlimited opens Cue Plus', () async {
    final viewModel = makeViewModel();
    await viewModel.start();
    final line = viewModel.line;
    // Остальные бесплатные потратили на других экранах.
    await mock.usageManager.recordGeneration();
    await mock.usageManager.recordGeneration();

    await viewModel.generate();
    await pumpEventQueue();

    // Шторка сама не открывается: на экране лимит, а «Go unlimited» — по нажатию.
    expect(actions, isEmpty);
    expect(viewModel.isLimitReached, isTrue);
    expect(viewModel.freeLimit, 3);
    expect(viewModel.line, line);
    expect(viewModel.isGenerating, isFalse);

    viewModel.goUnlimited();
    await pumpEventQueue();
    expect(actions, [OpeningLineAction.openPlus]);

    viewModel.didSubscribe();
    expect(viewModel.isLimitReached, isFalse);
  });

  test('a failed line shows the error until Try again writes one', () async {
    final lines = _FakeOpeningLineManager([
      const NetworkError(NetworkErrorCode.logical, statusCode: 500),
      const OpeningLine(id: 'line-1', text: 'hi there'),
    ]);
    final viewModel = makeViewModel(openingLineManager: lines);

    await viewModel.start();
    expect(viewModel.hasFailed, isTrue);
    expect(viewModel.line, isNull);
    expect(historyManager.obtainHistory(), isEmpty);

    final retrying = viewModel.generate();
    expect(viewModel.hasFailed, isFalse);
    await retrying;

    expect(viewModel.line?.text, 'hi there');
    expect(viewModel.hasFailed, isFalse);
  });
}
