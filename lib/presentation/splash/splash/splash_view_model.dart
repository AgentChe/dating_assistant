import 'package:dating_assistant/misc/components/view_model.dart';
import 'package:dating_assistant/misc/injector.dart';
import 'package:dating_assistant/service/profile/profile_manager.dart';
import 'package:dating_assistant/service/session/session_manager.dart';

enum SplashRoute { onboarding, main }

/// Стартовая логика: запускает SDK и решает, куда вести пользователя.
class SplashViewModel extends ViewModel<SplashRoute> {
  SplashViewModel({SessionManager? sessionManager, ProfileManager? profileManager})
    : _sessionManager = sessionManager ?? Injector.shared.sessionManager,
      _profileManager = profileManager ?? Injector.shared.profileManager;

  final SessionManager _sessionManager;

  final ProfileManager _profileManager;

  /// Без профиля — на онбординг. Сюда же добавятся конфиг с сервера и пейвол для тех, у кого нет подписки.
  Future<void> start() async {
    await _sessionManager.start();
    emit(_profileManager.profile == null ? SplashRoute.onboarding : SplashRoute.main);
  }
}
