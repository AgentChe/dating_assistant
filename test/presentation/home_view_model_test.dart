import 'package:dating_assistant/presentation/main/home/home_view_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  HomeViewModel at(int hour) => HomeViewModel(now: () => DateTime(2026, 11, 5, hour, 30));

  test('greets by the time of day', () {
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
    final viewModel = HomeViewModel(now: () => DateTime(2026, 11, 5, hour));
    var changes = 0;
    viewModel.addListener(() => changes++);
    expect(viewModel.greeting, 'Good morning');

    hour = 13;
    viewModel.refreshGreeting();

    expect(changes, 1);
    expect(viewModel.greeting, 'Good afternoon');
  });

  test('each entry point opens its feature', () async {
    final viewModel = HomeViewModel();
    final actions = <HomeAction>[];
    viewModel.actions.listen(actions.add);

    viewModel
      ..analyzeChat()
      ..openDatingAdvice()
      ..openOpeningLine()
      ..openMenu();
    await pumpEventQueue();

    expect(actions, [
      HomeAction.analyzeChat,
      HomeAction.openDatingAdvice,
      HomeAction.openOpeningLine,
      HomeAction.openMenu,
    ]);
  });
}
