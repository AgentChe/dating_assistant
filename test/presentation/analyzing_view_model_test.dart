import 'package:dating_assistant/presentation/analysis/analyzing/analyzing_view_model.dart';
import 'package:dating_assistant/service/analysis/model/chat_breakdown.dart';
import 'package:dating_assistant/transport/network_error.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_analysis.dart';

void main() {
  late ChatBreakdown breakdown;
  late List<AnalyzingAction> actions;

  setUpAll(() async => breakdown = await exampleBreakdown());

  AnalyzingViewModel makeViewModel(List<Object> results) {
    final viewModel = AnalyzingViewModel(screenshot: fakeScreenshot, analysisManager: FakeAnalysisManager(results));
    actions = [];
    viewModel.actions.listen(actions.add);
    return viewModel;
  }

  test('the finished breakdown is handed over', () async {
    final viewModel = makeViewModel([breakdown]);

    await viewModel.analyze();
    await pumpEventQueue();

    expect(viewModel.isFinished, isTrue);
    expect(actions.single, isA<AnalysisFinished>().having((action) => action.breakdown, 'breakdown', breakdown));
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
    expect(actions.single, isA<AnalysisLimitReached>());
  });

  test('a network error is retried while the user asks to', () async {
    final viewModel = makeViewModel([const NetworkError(NetworkErrorCode.serverNotAvailable), breakdown]);
    viewModel.tryAgain = (_) async => true;

    await viewModel.analyze();
    await pumpEventQueue();

    expect(actions.single, isA<AnalysisFinished>());
  });

  test('declining to retry cancels the analysis', () async {
    final viewModel = makeViewModel([const NetworkError(NetworkErrorCode.serverNotAvailable)]);
    viewModel.tryAgain = (_) async => false;

    await viewModel.analyze();
    await pumpEventQueue();

    expect(viewModel.isFinished, isFalse);
    expect(actions.single, isA<AnalysisCancelled>());
  });
}
