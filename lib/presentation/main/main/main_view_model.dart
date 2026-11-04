import 'package:dating_assistant/misc/components/view_model.dart';

/// Вкладки главного экрана (≈ TabView.Tab в Swift-проектах).
enum MainTab { home, history, profile }

/// Главный экран: какая вкладка открыта и какие уже созданы.
class MainViewModel extends ViewModel<Never> {
  var _selectedTab = MainTab.home;

  final _openedTabs = {MainTab.home};

  MainTab get selectedTab => _selectedTab;

  /// Вкладка создаётся, когда её впервые открыли, и дальше живёт со своим стеком экранов
  /// (≈ lazy var NavigationController в MainViewCoordinator).
  bool isOpened(MainTab tab) => _openedTabs.contains(tab);

  void select(MainTab tab) {
    if (tab == _selectedTab) return;
    _selectedTab = tab;
    _openedTabs.add(tab);
    notifyListeners();
  }
}
