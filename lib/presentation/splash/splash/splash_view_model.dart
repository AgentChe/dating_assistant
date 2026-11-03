import 'package:dating_assistant/misc/components/view_model.dart';
import 'package:dating_assistant/misc/injector.dart';
import 'package:dating_assistant/service/session/session_manager.dart';

enum SplashRoute { onboarding, main }

/// Стартовая логика: решает, куда вести пользователя.
class SplashViewModel extends ViewModel<SplashRoute> {
  SplashViewModel({SessionManager? sessionManager})
    : _sessionManager = sessionManager ?? Injector.shared.sessionManager;

  final SessionManager _sessionManager;

  /// Сюда же добавятся инициализация SDK, конфиг с сервера, проверка подписки.
  void start() {
    emit(_sessionManager.isAuthorized ? SplashRoute.main : SplashRoute.onboarding);
  }
}
