import 'package:dating_assistant/misc/components/view_model.dart';
import 'package:dating_assistant/misc/injector.dart';
import 'package:dating_assistant/service/profile/profile_manager.dart';
import 'package:dating_assistant/service/session/session_manager.dart';

enum SplashRoute { onboarding, paygate, main }

/// Стартовая логика: запускает SDK и решает, куда вести пользователя.
class SplashViewModel extends ViewModel<SplashRoute> {
  SplashViewModel({SessionManager? sessionManager, ProfileManager? profileManager})
    : _sessionManager = sessionManager ?? Injector.shared.sessionManager,
      _profileManager = profileManager ?? Injector.shared.profileManager;

  final SessionManager _sessionManager;

  final ProfileManager _profileManager;

  /// Без профиля — на онбординг, без подписки — на пейгейт (как paygateTransitionMain в Swift-проектах).
  /// Сюда же добавится конфиг с сервера.
  Future<void> start() async {
    await _sessionManager.start();
    if (_profileManager.profile == null) {
      emit(SplashRoute.onboarding);
      return;
    }

    final hasSubscription = await _sessionManager.hasActiveSubscriptions();
    emit(hasSubscription ? SplashRoute.main : SplashRoute.paygate);
  }
}
