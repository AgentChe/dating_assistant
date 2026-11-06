import 'dart:typed_data';

import 'package:dating_assistant/misc/media/screenshot_picker.dart';
import 'package:dating_assistant/presentation/analysis/analyze_chat/analyze_chat_view_model.dart';
import 'package:dating_assistant/service/usage/model/usage.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_analysis.dart';
import '../fakes/fake_managers.dart';

class _FakePicker implements ScreenshotPicker {
  Uint8List? screenshot = fakeScreenshot;

  var picks = 0;

  @override
  Future<Uint8List?> pick() async {
    picks++;
    return screenshot;
  }
}

void main() {
  late _FakePicker picker;
  late FakeSessionManager sessionManager;
  late FakeUsageManager usageManager;
  late List<AnalyzeChatAction> actions;

  Future<AnalyzeChatViewModel> makeViewModel() async {
    final viewModel = AnalyzeChatViewModel(
      picker: picker,
      sessionManager: sessionManager,
      usageManager: usageManager,
    );
    viewModel.actions.listen(actions.add);
    await viewModel.load();
    return viewModel;
  }

  setUp(() {
    picker = _FakePicker();
    sessionManager = FakeSessionManager(isPlus: false);
    usageManager = FakeUsageManager(usage: const Usage(used: 1, limit: 3));
    actions = [];
  });

  test('a picked screenshot goes to the analysis', () async {
    final viewModel = await makeViewModel();

    await viewModel.chooseFromPhotos();
    await pumpEventQueue();

    expect(picker.picks, 1);
    expect(
      actions.single,
      isA<AnalyzeScreenshot>().having((action) => action.screenshot, 'screenshot', fakeScreenshot),
    );
  });

  test('closing the gallery changes nothing', () async {
    picker.screenshot = null;
    final viewModel = await makeViewModel();

    await viewModel.chooseFromPhotos();
    await pumpEventQueue();

    expect(actions, isEmpty);
  });

  test('without free generations Cue Plus opens instead of the gallery', () async {
    usageManager.usage = const Usage(used: 3, limit: 3);
    final viewModel = await makeViewModel();

    await viewModel.chooseFromPhotos();
    await pumpEventQueue();

    expect(picker.picks, 0);
    expect(actions.single, isA<OpenPlus>());

    // Подписку оформили — дальше в галерею.
    viewModel.didSubscribe();
    await viewModel.chooseFromPhotos();
    await pumpEventQueue();

    expect(picker.picks, 1);
    expect(actions.last, isA<AnalyzeScreenshot>());
  });

  test('Cue Plus has no limit to check', () async {
    sessionManager.isPlus = true;
    usageManager.usage = const Usage(used: 3, limit: 3);
    final viewModel = await makeViewModel();

    await viewModel.chooseFromPhotos();
    await pumpEventQueue();

    expect(actions.single, isA<AnalyzeScreenshot>());
  });

  test('if the usage is unknown the server decides', () async {
    usageManager.error = Exception('offline');
    final viewModel = await makeViewModel();

    await viewModel.chooseFromPhotos();
    await pumpEventQueue();

    expect(actions.single, isA<AnalyzeScreenshot>());
  });

  test('the server limit stops the next pick', () async {
    final viewModel = await makeViewModel();

    viewModel.didReachLimit();
    await viewModel.chooseFromPhotos();
    await pumpEventQueue();

    expect(picker.picks, 0);
    expect(actions.single, isA<OpenPlus>());
  });
}
