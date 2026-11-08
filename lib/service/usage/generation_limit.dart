import 'dart:async';

import 'package:dating_assistant/misc/injector.dart';
import 'package:dating_assistant/service/session/session_manager.dart';
import 'package:dating_assistant/service/usage/model/usage.dart';
import 'package:dating_assistant/service/usage/usage_manager.dart';
import 'package:dating_assistant/service/usage/usage_mediator.dart';
import 'package:flutter/foundation.dart';

/// Остались ли бесплатные генерации — чтобы предложить Cue Plus до запроса, а не после.
///
/// Последнее слово за сервером: если лимит неизвестен, генерация уходит на сервер, и он ответит 402.
/// Сообщает слушателям, когда счётчик обновился.
class GenerationLimit extends ChangeNotifier {
  /// Бесплатных генераций в неделю — на случай, когда сервер сказал «хватит» раньше, чем прислал счётчик.
  static const freePerWeek = 3;

  GenerationLimit({SessionManager? sessionManager, UsageManager? usageManager, UsageMediator? usageMediator})
    : _sessionManager = sessionManager ?? Injector.shared.sessionManager,
      _usageManager = usageManager ?? Injector.shared.usageManager {
    // Генерацию потратили — к следующему нажатию лимит уже известен.
    _usageChanges = (usageMediator ?? Injector.shared.usageMediator).changes.listen((_) => load());
  }

  final SessionManager _sessionManager;

  final UsageManager _usageManager;

  late final StreamSubscription<void> _usageChanges;

  Usage? _usage;

  bool? _isReached;

  var _isDisposed = false;

  /// Бесплатные на этой неделе кончились; пока неизвестно — false.
  bool get isReached => _isReached ?? false;

  /// Сколько бесплатных осталось; null — Cue Plus или сервер не ответил.
  Usage? get usage => _usage;

  Future<void> load() async {
    if (await _sessionManager.hasActiveSubscriptions()) {
      didSubscribe();
      return;
    }
    try {
      final usage = await _usageManager.obtainUsage();
      _usage = usage;
      _isReached = usage.left == 0;
      notifyListeners();
    } catch (error) {
      debugPrint('GenerationLimit: cannot load the usage: $error');
    }
  }

  /// Оформили Cue Plus — лимита больше нет.
  void didSubscribe() {
    _usage = null;
    _isReached = false;
    notifyListeners();
  }

  /// Сервер ответил, что генерации кончились.
  void didReachLimit() {
    _isReached = true;
    notifyListeners();
  }

  @override
  void notifyListeners() {
    if (!_isDisposed) super.notifyListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _usageChanges.cancel();
    super.dispose();
  }
}
