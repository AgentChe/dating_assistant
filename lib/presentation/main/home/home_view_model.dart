import 'package:dating_assistant/misc/components/view_model.dart';

enum HomeAction { openMenu, analyzeChat, openDatingAdvice, openOpeningLine }

/// Вкладка «Main» (аналог HomeViewModel из Swift-проектов): приветствие и входы в три фичи.
class HomeViewModel extends ViewModel<HomeAction> {
  HomeViewModel({DateTime Function()? now}) : _now = now ?? DateTime.now;

  final DateTime Function() _now;

  /// «Good evening» — по времени на устройстве. В Figma только вечерний вариант.
  String get greeting => switch (_now().hour) {
    >= 5 && < 12 => 'Good morning',
    >= 12 && < 18 => 'Good afternoon',
    _ => 'Good evening',
  };

  /// Приложение вернулось из фона — время суток могло смениться.
  void refreshGreeting() => notifyListeners();

  void openMenu() => emit(HomeAction.openMenu);

  void analyzeChat() => emit(HomeAction.analyzeChat);

  void openDatingAdvice() => emit(HomeAction.openDatingAdvice);

  void openOpeningLine() => emit(HomeAction.openOpeningLine);
}
