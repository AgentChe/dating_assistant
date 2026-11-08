import 'package:dating_assistant/presentation/opening_line/opening_line_source/opening_line_source_view_model.dart';
import 'package:dating_assistant/service/history/history_manager.dart';
import 'package:dating_assistant/service/usage/generation_limit.dart';
import 'package:dating_assistant/service/usage/model/usage.dart';
import 'package:dating_assistant/service/usage/usage_mediator.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_analysis.dart';
import '../fakes/fake_history.dart';
import '../fakes/fake_managers.dart';
import '../fakes/fake_opening_line.dart';

void main() {
  late MockOpeningLines mock;
  late FakeScreenshotPicker picker;
  late FakeUsageManager usageManager;
  late HistoryManager historyManager;
  late List<OpeningLineSourceAction> actions;

  Future<OpeningLineSourceViewModel> makeViewModel() async {
    final viewModel = OpeningLineSourceViewModel(
      picker: picker,
      openingLineManager: mock.manager,
      historyManager: historyManager,
      profileManager: mock.profileManager,
      limit: GenerationLimit(
        sessionManager: FakeSessionManager(isPlus: false),
        usageManager: usageManager,
        usageMediator: UsageMediator(),
      ),
    );
    viewModel.actions.listen(actions.add);
    await viewModel.load();
    return viewModel;
  }

  setUp(() async {
    mock = await mockOpeningLines();
    picker = FakeScreenshotPicker();
    usageManager = FakeUsageManager(usage: const Usage(used: 1, limit: 3));
    historyManager = await memoryHistoryManager();
    actions = [];
  });

  test('a line the bio scan finished starts a session in the history', () async {
    final viewModel = await makeViewModel();
    final line = await viewModel.generateFromBio(fakeScreenshot);
    // Сканирование ещё не закончилось — в истории пусто.
    expect(historyManager.obtainHistory(), isEmpty);

    final session = viewModel.keep(line);
    await pumpEventQueue();

    expect(session.lines, [line.text]);
    expect(session.match?.name, 'Nika');
    expect(historyManager.obtainOpeningLines(session.id)?.lines, [line.text]);
  });

  test('Upload their bio opens the gallery and scans the picked screenshot', () async {
    final viewModel = await makeViewModel();

    await viewModel.uploadBio();
    await pumpEventQueue();

    expect(picker.picks, 1);
    expect(actions.single, isA<ScanBio>().having((action) => action.screenshot, 'screenshot', fakeScreenshot));

    // Сканирование ждёт первую фразу по анкете.
    final line = await viewModel.generateFromBio(fakeScreenshot);
    expect(line.match?.name, 'Nika');
  });

  test('closing the gallery changes nothing', () async {
    picker.screenshot = null;
    final viewModel = await makeViewModel();

    await viewModel.uploadBio();
    await pumpEventQueue();

    expect(actions, isEmpty);
  });

  test('Type it out and Just give me one lead to their screens', () async {
    final viewModel = await makeViewModel();

    viewModel
      ..typeItOut()
      ..giveMeOne();
    await pumpEventQueue();

    expect(actions, [isA<TypeItOut>(), isA<GiveMeOne>()]);
  });

  test('without free generations every way opens Cue Plus', () async {
    usageManager.usage = const Usage(used: 3, limit: 3);
    final viewModel = await makeViewModel();

    await viewModel.uploadBio();
    viewModel
      ..typeItOut()
      ..giveMeOne();
    await pumpEventQueue();

    expect(picker.picks, 0);
    expect(actions, [isA<OpenPlus>(), isA<OpenPlus>(), isA<OpenPlus>()]);

    viewModel.didSubscribe();
    viewModel.giveMeOne();
    await pumpEventQueue();
    expect(actions.last, isA<GiveMeOne>());
  });
}
