import 'dart:async';

import 'package:dating_assistant/misc/components/view_model.dart';
import 'package:dating_assistant/misc/injector.dart';
import 'package:dating_assistant/service/analytics/analytics_manager.dart';
import 'package:dating_assistant/service/profile/profile_manager.dart';
import 'package:dating_assistant/service/session/session_manager.dart';

enum SplashRoute { onboarding, paygate, main }

/// Стартовая логика: запускает SDK и решает, куда вести пользователя.
class SplashViewModel extends ViewModel<SplashRoute> {
  SplashViewModel({SessionManager? sessionManager, ProfileManager? profileManager, AnalyticsManager? analyticsManager})
    : _sessionManager = sessionManager ?? Injector.shared.sessionManager,
      _profileManager = profileManager ?? Injector.shared.profileManager,
      _analyticsManager = analyticsManager ?? Injector.shared.analyticsManager;

  final SessionManager _sessionManager;

  final ProfileManager _profileManager;

  final AnalyticsManager _analyticsManager;

  /// Без профиля — на онбординг, без подписки — на пейгейт (как paygateTransitionMain в Swift-проектах).
  /// Сюда же добавится конфиг с сервера.
  Future<void> start() async {
    await _sessionManager.start();
    // Amplitude — после OtterScale: событиям нужен anonymous_id. Переход дальше его не ждёт.
    unawaited(_analyticsManager.start());
    if (_profileManager.profile == null) {
      emit(SplashRoute.onboarding);
      return;
    }

    final hasSubscription = await _sessionManager.hasActiveSubscriptions();
    emit(hasSubscription ? SplashRoute.main : SplashRoute.paygate);
  }
}
