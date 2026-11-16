import 'dart:async';

import 'package:dating_assistant/misc/components/view_model.dart';
import 'package:dating_assistant/misc/injector.dart';
import 'package:dating_assistant/service/consent/ai_consent_manager.dart';
import 'package:dating_assistant/service/history/history_manager.dart';
import 'package:dating_assistant/service/profile/profile_manager.dart';

enum AiPrivacyAction { openPrivacyPolicy, confirmDeletion, dataDeleted }

/// «AI & privacy» в профиле (Figma 484:3499): согласие на ИИ можно выключить, открыть политику и удалить данные.
class AiPrivacyViewModel extends ViewModel<AiPrivacyAction> {
  AiPrivacyViewModel({
    AiConsentManager? consentManager,
    HistoryManager? historyManager,
    ProfileManager? profileManager,
  }) : _consentManager = consentManager ?? Injector.shared.aiConsentManager,
       _historyManager = historyManager ?? Injector.shared.historyManager,
       _profileManager = profileManager ?? Injector.shared.profileManager {
    // Согласие могут дать и на экране согласия, пока этот открыт под ним.
    _consentChanges = _consentManager.changes.listen((_) => notifyListeners());
  }

  final AiConsentManager _consentManager;

  final HistoryManager _historyManager;

  final ProfileManager _profileManager;

  late final StreamSubscription<bool> _consentChanges;

  bool get isSharingAllowed => _consentManager.isGranted;

  /// Выключили — новые запросы к ИИ не уходят, пока пользователь не разрешит снова.
  Future<void> setSharingAllowed(bool isAllowed) => _consentManager.setGranted(isAllowed);

  void openPrivacyPolicy() => emit(AiPrivacyAction.openPrivacyPolicy);

  /// «Delete my data» сначала спрашивает.
  void deleteData() => emit(AiPrivacyAction.confirmDeletion);

  /// Удаление подтверждено: стираются история, голос и ответы с онбординга, а с ними и согласие на ИИ.
  /// Подписка остаётся — она в App Store, — и счётчик бесплатных генераций тоже.
  Future<void> confirmDeletion() async {
    await _historyManager.deleteAll();
    await _profileManager.delete();
    await _consentManager.setGranted(false);
    emit(AiPrivacyAction.dataDeleted);
  }

  @override
  void dispose() {
    _consentChanges.cancel();
    super.dispose();
  }
}
