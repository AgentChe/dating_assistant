import 'package:dating_assistant/presentation/main/home/home_view_model.dart';
import 'package:dating_assistant/service/usage/model/usage.dart';
import 'package:dating_assistant/service/usage/usage_mediator.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_analysis.dart';
import '../fakes/fake_managers.dart';

void main() {
  late FakeScreenshotPicker picker;
  late FakeSessionManager sessionManager;
  late FakeUsageManager usageManager;
  late UsageMediator usageMediator;
  late List<HomeAction> actions;

  HomeViewModel makeViewModel({DateTime Function()? now}) {
    final viewModel = HomeViewModel(
      now: now,
      picker: picker,
      analysisManager: FakeAnalysisManager([]),
      sessionManager: sessionManager,
      usageManager: usageManager,
      usageMediator: usageMediator,
    );
    viewModel.actions.listen(actions.add);
    return viewModel;
  }

  Future<HomeViewModel> loadedViewModel() async {
    final viewModel = makeViewModel();
    await viewModel.loadUsage();
    return viewModel;
  }

  setUp(() {
    picker = FakeScreenshotPicker();
    sessionManager = FakeSessionManager(isPlus: false);
    usageManager = FakeUsageManager(usage: const Usage(used: 1, limit: 3));
    usageMediator = UsageMediator();
    actions = [];
  });

  test('greets by the time of day', () {
    HomeViewModel at(int hour) => makeViewModel(now: () => DateTime(2026, 11, 5, hour, 30));

    expect(at(4).greeting, 'Good evening');
    expect(at(5).greeting, 'Good morning');
    expect(at(11).greeting, 'Good morning');
    expect(at(12).greeting, 'Good afternoon');
    expect(at(17).greeting, 'Good afternoon');
    expect(at(18).greeting, 'Good evening');
    expect(at(23).greeting, 'Good evening');
  });

  test('the greeting follows the clock after the app comes back', () {
    var hour = 11;
    final viewModel = makeViewModel(now: () => DateTime(2026, 11, 5, hour));
    var changes = 0;
    viewModel.addListener(() => changes++);
    expect(viewModel.greeting, 'Good morning');

    hour = 13;
    viewModel.refresh();

    expect(changes, 1);
    expect(viewModel.greeting, 'Good afternoon');
  });

  test('Upload screenshot opens the gallery and sends the picked screenshot to the analysis', () async {
    final viewModel = await loadedViewModel();

    await viewModel.uploadScreenshot();
    await pumpEventQueue();

    expect(picker.picks, 1);
    expect(
      actions.single,
      isA<AnalyzeScreenshot>().having((action) => action.screenshot, 'screenshot', fakeScreenshot),
    );
  });

  test('closing the gallery changes nothing', () async {
    picker.screenshot = null;
    final viewModel = await loadedViewModel();

    await viewModel.uploadScreenshot();
    await pumpEventQueue();

    expect(actions, isEmpty);
  });

  test('without free generations Cue Plus opens instead of the gallery', () async {
    usageManager.usage = const Usage(used: 3, limit: 3);
    final viewModel = await loadedViewModel();

    await viewModel.uploadScreenshot();
    await pumpEventQueue();

    expect(picker.picks, 0);
    expect(actions.single, isA<OpenPlus>());

    // Подписку оформили — дальше в галерею.
    viewModel.didSubscribe();
    await viewModel.uploadScreenshot();
    await pumpEventQueue();

    expect(picker.picks, 1);
    expect(actions.last, isA<AnalyzeScreenshot>());
  });

  test('a generation spent elsewhere updates the limit before the next tap', () async {
    final viewModel = await loadedViewModel();

    usageManager.usage = const Usage(used: 3, limit: 3);
    usageMediator.notifyGenerationUsed();
    await pumpEventQueue();
    await viewModel.uploadScreenshot();
    await pumpEventQueue();

    expect(picker.picks, 0);
    expect(actions.single, isA<OpenPlus>());
  });

  test('Cue Plus has no limit to check', () async {
    sessionManager.isPlus = true;
    usageManager.usage = const Usage(used: 3, limit: 3);
    final viewModel = await loadedViewModel();

    await viewModel.uploadScreenshot();
    await pumpEventQueue();

    expect(actions.single, isA<AnalyzeScreenshot>());
  });

  test('if the usage is unknown the server decides', () async {
    usageManager.error = Exception('offline');
    final viewModel = await loadedViewModel();

    await viewModel.uploadScreenshot();
    await pumpEventQueue();

    expect(actions.single, isA<AnalyzeScreenshot>());
  });

  test('the server limit stops the next tap', () async {
    final viewModel = await loadedViewModel();

    viewModel.didReachLimit();
    await viewModel.uploadScreenshot();
    await pumpEventQueue();

    expect(picker.picks, 0);
    expect(actions.single, isA<OpenPlus>());
  });

  test('the features and the menu send their actions', () async {
    final viewModel = makeViewModel();

    viewModel
      ..openDatingAdvice()
      ..openOpeningLine()
      ..openMenu();
    await pumpEventQueue();

    expect(actions, [isA<OpenDatingAdvice>(), isA<OpenOpeningLine>(), isA<OpenMenu>()]);
  });
}
