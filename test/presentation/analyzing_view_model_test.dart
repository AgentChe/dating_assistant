import 'package:dating_assistant/presentation/analysis/analyzing/analyzing_view_model.dart';
import 'package:dating_assistant/service/analysis/model/chat_breakdown.dart';
import 'package:dating_assistant/transport/network_error.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_analysis.dart';

void main() {
  late ChatBreakdown breakdown;
  late List<AnalyzingAction<ChatBreakdown>> actions;

  setUpAll(() async => breakdown = await exampleBreakdown());

  AnalyzingViewModel<ChatBreakdown> makeViewModel(List<Object> results) {
    final manager = FakeAnalysisManager(results);
    final viewModel = AnalyzingViewModel<ChatBreakdown>(task: () => manager.analyzeScreenshot(fakeScreenshot));
    actions = [];
    viewModel.actions.listen(actions.add);
    return viewModel;
  }

  test('the finished breakdown is handed over', () async {
    final viewModel = makeViewModel([breakdown]);

    await viewModel.analyze();
    await pumpEventQueue();

    expect(viewModel.isFinished, isTrue);
    expect(
      actions.single,
      isA<AnalysisFinished<ChatBreakdown>>().having((action) => action.result, 'result', breakdown),
    );
  });

  test('the generation limit is not retried', () async {
    final viewModel = makeViewModel([const NetworkError(NetworkErrorCode.logical, statusCode: 402)]);
    var questions = 0;
    viewModel.tryAgain = (_) async {
      questions++;
      return true;
    };

    await viewModel.analyze();
    await pumpEventQueue();

    expect(questions, 0);
    expect(actions.single, isA<AnalysisLimitReached<ChatBreakdown>>());
  });

  test('a network error is retried while the user asks to', () async {
    final viewModel = makeViewModel([const NetworkError(NetworkErrorCode.serverNotAvailable), breakdown]);
    viewModel.tryAgain = (_) async => true;

    await viewModel.analyze();
    await pumpEventQueue();

    expect(actions.single, isA<AnalysisFinished<ChatBreakdown>>());
  });

  test('declining to retry cancels the analysis', () async {
    final viewModel = makeViewModel([const NetworkError(NetworkErrorCode.serverNotAvailable)]);
    viewModel.tryAgain = (_) async => false;

    await viewModel.analyze();
    await pumpEventQueue();

    expect(viewModel.isFinished, isFalse);
    expect(actions.single, isA<AnalysisCancelled<ChatBreakdown>>());
  });
}
