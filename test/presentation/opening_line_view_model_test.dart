import 'package:dating_assistant/presentation/opening_line/opening_line/opening_line_view_model.dart';
import 'package:dating_assistant/service/opening_line/model/opening_line.dart';
import 'package:dating_assistant/service/profile/model/spice_level.dart';
import 'package:dating_assistant/service/usage/generation_limit.dart';
import 'package:dating_assistant/service/usage/usage_manager.dart';
import 'package:dating_assistant/transport/mock/mock_api_transport.dart';
import 'package:dating_assistant/transport/mock/mock_server.dart';
import 'package:dating_assistant/transport/mock/routes/usage_mock_routes.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_analysis.dart';
import '../fakes/fake_managers.dart';
import '../fakes/fake_opening_line.dart';

void main() {
  late MockOpeningLines mock;
  late List<OpeningLineAction> actions;

  OpeningLineViewModel makeViewModel({MatchDetails? match, OpeningLine? firstLine}) {
    final viewModel = OpeningLineViewModel(
      match: match,
      firstLine: firstLine,
      openingLineManager: mock.manager,
      profileManager: mock.profileManager,
      // Лимит считает тот же мок-сервер, что и фразы.
      limit: GenerationLimit(
        sessionManager: FakeSessionManager(isPlus: false),
        usageManager: UsageManager(
          MockApiTransport(
            server: MockServer(mock.database, generationTime: Duration.zero),
            latency: Duration.zero,
          ),
        ),
        usageMediator: mock.usageMediator,
      ),
    );
    viewModel.actions.listen(actions.add);
    return viewModel;
  }

  setUp(() async {
    mock = await mockOpeningLines();
    actions = [];
  });

  test('without a ready line the screen writes the first one in the profile spice', () async {
    final viewModel = makeViewModel();
    expect(viewModel.spice, SpiceLevel.warm);

    await viewModel.start();
    await pumpEventQueue();

    expect(viewModel.line?.text, isNotEmpty);
    expect(viewModel.isGenerating, isFalse);
    expect(viewModel.caption, '2 of 3 free generations left');
  });

  test('a line from the bio scan is shown as is, and the next one uses what the server read', () async {
    final first = await mock.manager.generate(spice: SpiceLevel.warm, profileScreenshot: fakeScreenshot);
    final viewModel = makeViewModel(firstLine: first);

    await viewModel.start();
    expect(viewModel.line, first);

    viewModel.selectSpice(SpiceLevel.spicy);
    await viewModel.generate();

    expect(viewModel.line?.text, isNot(first.text));
    // Острота из ползунка, а имя и интересы — из прочитанной анкеты.
    expect(viewModel.line?.text, anyOf(contains('Nika'), contains('into mountains')));
  });

  test('Another one never repeats a line', () async {
    final viewModel = makeViewModel(match: const MatchDetails(name: 'Sam'));
    await viewModel.start();
    final seen = {viewModel.line!.text};

    await viewModel.generate();

    expect(seen.add(viewModel.line!.text), isTrue);
  });

  test('without free generations Cue Plus opens and the line stays', () async {
    final viewModel = makeViewModel();
    await viewModel.start();
    final line = viewModel.line;
    // Остальные бесплатные потратили на других экранах.
    await UsageMockRoutes.consumeGeneration(mock.database);
    await UsageMockRoutes.consumeGeneration(mock.database);

    await viewModel.generate();
    await pumpEventQueue();

    expect(actions, [OpeningLineAction.openPlus]);
    expect(viewModel.line, line);
    expect(viewModel.isGenerating, isFalse);

    // Счётчик уже ноль — следующее нажатие сразу предлагает Cue Plus, без запроса.
    await viewModel.generate();
    await pumpEventQueue();
    expect(actions, [OpeningLineAction.openPlus, OpeningLineAction.openPlus]);
  });
}
