import 'package:dating_assistant/presentation/main/main/main_view_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('starts on Main and creates other tabs only when they are opened', () {
    final viewModel = MainViewModel();
    var changes = 0;
    viewModel.addListener(() => changes++);

    expect(viewModel.selectedTab, MainTab.home);
    expect(MainTab.values.where(viewModel.isOpened), [MainTab.home]);

    viewModel.select(MainTab.profile);
    expect(viewModel.selectedTab, MainTab.profile);
    expect(MainTab.values.where(viewModel.isOpened), [MainTab.home, MainTab.profile]);

    viewModel.select(MainTab.home);
    expect(viewModel.selectedTab, MainTab.home);
    expect(viewModel.isOpened(MainTab.profile), isTrue);
    expect(changes, 2);
  });

  test('selecting the open tab changes nothing', () {
    final viewModel = MainViewModel();
    var changes = 0;
    viewModel.addListener(() => changes++);

    viewModel.select(MainTab.home);

    expect(changes, 0);
  });
}
