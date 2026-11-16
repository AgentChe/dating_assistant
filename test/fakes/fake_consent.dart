import 'dart:async';

import 'package:dating_assistant/service/consent/ai_consent_manager.dart';

/// Согласие на ИИ в памяти. По умолчанию уже дано — как у пользователя, который разрешил его на первом запросе.
class FakeAiConsentManager implements AiConsentManager {
  FakeAiConsentManager({this.isGranted = true});

  @override
  bool isGranted;

  /// Сколько раз пришлось спросить пользователя.
  var asks = 0;

  final _changes = StreamController<bool>.broadcast();

  @override
  Future<bool> Function()? askUser;

  @override
  Stream<bool> get changes => _changes.stream;

  @override
  Future<void> setGranted(bool isGranted) async {
    this.isGranted = isGranted;
    _changes.add(isGranted);
  }

  @override
  Future<void> ensureGranted() async {
    if (isGranted) return;
    asks++;
    if (!(await askUser?.call() ?? false)) throw const AiConsentDeclined();
    await setGranted(true);
  }
}
