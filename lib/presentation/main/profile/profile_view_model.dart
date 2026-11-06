import 'dart:async';

import 'package:dating_assistant/misc/components/view_model.dart';
import 'package:dating_assistant/misc/global_definitions.dart';
import 'package:dating_assistant/misc/injector.dart';
import 'package:dating_assistant/presentation/splash/paygate/paygate_view_model.dart';
import 'package:dating_assistant/service/profile/model/age_range.dart';
import 'package:dating_assistant/service/profile/model/dating_goal.dart';
import 'package:dating_assistant/service/profile/model/gender.dart';
import 'package:dating_assistant/service/profile/model/profile.dart';
import 'package:dating_assistant/service/profile/model/spice_level.dart';
import 'package:dating_assistant/service/profile/profile_manager.dart';
import 'package:dating_assistant/service/purchase/model/purchase_result.dart';
import 'package:dating_assistant/service/purchase/purchase_manager.dart';
import 'package:dating_assistant/service/session/model/subscription.dart';
import 'package:dating_assistant/service/session/session_manager.dart';
import 'package:dating_assistant/service/usage/model/usage.dart';
import 'package:dating_assistant/service/usage/usage_manager.dart';
import 'package:dating_assistant/service/usage/usage_mediator.dart';
import 'package:flutter/foundation.dart';

/// Ответы «About you», которые меняются в шторке.
typedef AboutYou = ({Gender gender, AgeRange ageRange, DatingGoal goal});

/// Что показывает карточка плана.
sealed class ProfilePlan {
  const ProfilePlan();
}

/// Бесплатный план; [usage] null — сервер не ответил, сколько генераций осталось.
final class FreePlan extends ProfilePlan {
  const FreePlan(this.usage);

  final Usage? usage;
}

/// Cue Plus; [subscription] null — SDK не прислал подробностей.
final class PlusPlan extends ProfilePlan {
  const PlusPlan({this.subscription, this.price});

  final Subscription? subscription;

  /// «$7.99 per week» — цена тарифа из магазина; null — магазин не ответил или тариф не наш.
  final String? price;
}

enum ProfileAction { openAboutYou, openPlus, openSubscriptions }

/// Профиль: ответы с онбординга, острота по умолчанию и план (аналог ProfileViewModel из Swift-проектов).
class ProfileViewModel extends ViewModel<ProfileAction> {
  ProfileViewModel({
    ProfileManager? profileManager,
    SessionManager? sessionManager,
    PurchaseManager? purchaseManager,
    UsageManager? usageManager,
    UsageMediator? usageMediator,
    this.yearlyId = GlobalDefinitions.paygateYearlyId,
    this.weeklyId = GlobalDefinitions.paygateWeeklyId,
  }) : _profileManager = profileManager ?? Injector.shared.profileManager,
       _sessionManager = sessionManager ?? Injector.shared.sessionManager,
       _purchaseManager = purchaseManager ?? Injector.shared.purchaseManager,
       _usageManager = usageManager ?? Injector.shared.usageManager {
    _profile = _profileManager.profile;
    // Вкладка живёт всё время: генерацию потратили на другом экране — обновляем счётчик.
    _usageChanges = (usageMediator ?? Injector.shared.usageMediator).changes.listen((_) => loadPlan());
  }

  final String yearlyId;

  final String weeklyId;

  final ProfileManager _profileManager;

  final SessionManager _sessionManager;

  final PurchaseManager _purchaseManager;

  final UsageManager _usageManager;

  late final StreamSubscription<void> _usageChanges;

  Profile? _profile;

  ProfilePlan? _plan;

  var _isRestoring = false;

  PaygateFailure? _failure;

  /// null — онбординг не пройден; после него профиль есть всегда.
  Profile? get profile => _profile;

  /// null, пока план загружается.
  ProfilePlan? get plan => _plan;

  bool get isRestoring => _isRestoring;

  PaygateFailure? get failure => _failure;

  Future<void> loadPlan() async {
    if (await _sessionManager.hasActiveSubscriptions()) {
      final subscription = await _sessionManager.activeSubscription();
      _plan = PlusPlan(subscription: subscription, price: await _priceOf(subscription));
    } else {
      _plan = FreePlan(await _obtainUsage());
    }
    notifyListeners();
  }

  /// Острота сохраняется сразу — «Saved automatically».
  Future<void> selectSpice(SpiceLevel spice) => _update((profile) => profile.copyWith(spice: spice));

  Future<void> updateAboutYou(AboutYou aboutYou) => _update(
    (profile) => profile.copyWith(gender: aboutYou.gender, ageRange: aboutYou.ageRange, goal: aboutYou.goal),
  );

  void openAboutYou() => emit(ProfileAction.openAboutYou);

  void goUnlimited() => emit(ProfileAction.openPlus);

  void manageSubscription() => emit(ProfileAction.openSubscriptions);

  Future<void> restore() async {
    if (_isRestoring) return;

    _isRestoring = true;
    _failure = null;
    notifyListeners();

    try {
      switch (await _purchaseManager.restore()) {
        case PurchaseResult.subscribed:
          await loadPlan();
        case PurchaseResult.notSubscribed:
          _failure = PaygateFailure.nothingToRestore;
        case PurchaseResult.cancelled:
          break;
      }
    } catch (error) {
      debugPrint('ProfileViewModel: $error');
      _failure = PaygateFailure.restoreFailed;
    }

    _isRestoring = false;
    notifyListeners();
  }

  void dismissFailure() {
    _failure = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _usageChanges.cancel();
    super.dispose();
  }

  Future<void> _update(Profile Function(Profile profile) change) async {
    final profile = _profile;
    if (profile == null) return;

    _profile = change(profile);
    notifyListeners();
    await _profileManager.save(_profile!);
  }

  Future<Usage?> _obtainUsage() async {
    try {
      return await _usageManager.obtainUsage();
    } catch (error) {
      // Без счётчика карточка просто не показывает, сколько осталось.
      debugPrint('ProfileViewModel: cannot load the usage: $error');
      return null;
    }
  }

  Future<String?> _priceOf(Subscription? subscription) async {
    final id = subscription?.productId ?? '';
    final period = id.isEmpty
        ? null
        : id == weeklyId
        ? 'week'
        : id == yearlyId
        ? 'year'
        : null;
    if (period == null) return null;

    try {
      final product = (await _purchaseManager.obtainProducts([id])).firstOrNull;
      return product == null ? null : '${product.price} per $period';
    } catch (error) {
      debugPrint('ProfileViewModel: cannot load the subscription price: $error');
      return null;
    }
  }
}
