import 'dart:async';

import 'package:shared_preferences/shared_preferences.dart';

/// Согласие на передачу переписок ИИ (правило App Review 5.1.2(i)): пока его нет, приложение ничего
/// не отправляет на сервер. Даётся на экране согласия, меняется в профиле («AI & privacy»).
///
/// Менеджеры разбора, коуча и фраз вызывают [ensureGranted] перед каждым запросом. Спросить пользователя
/// сервис не может — у него нет экранов, поэтому вопрос задаёт [askUser], его ставит приложение
/// (как делегат в Swift-проектах).
class AiConsentManager {
  AiConsentManager(this._preferences);

  static const _key = 'ai_consent';

  final SharedPreferencesWithCache _preferences;

  final _changes = StreamController<bool>.broadcast();

  /// Показывает экран согласия; true — пользователь разрешил.
  Future<bool> Function()? askUser;

  Future<void>? _asking;

  bool get isGranted => _preferences.getBool(_key) ?? false;

  /// Согласие дали или отозвали — строка «AI & privacy» в профиле обновляется.
  Stream<bool> get changes => _changes.stream;

  Future<void> setGranted(bool isGranted) async {
    if (isGranted == this.isGranted) return;
    await _preferences.setBool(_key, isGranted);
    _changes.add(isGranted);
  }

  /// Перед каждым запросом к ИИ. Согласия нет — спрашивает; отказ — [AiConsentDeclined], и запрос не уходит.
  Future<void> ensureGranted() async {
    if (isGranted) return;
    // Два запроса сразу спрашивают один раз.
    await (_asking ??= _ask().whenComplete(() => _asking = null));
  }

  Future<void> _ask() async {
    final isAllowed = await askUser?.call() ?? false;
    if (!isAllowed) throw const AiConsentDeclined();
    await setGranted(true);
  }

  static bool isDeclined(Object error) => error is AiConsentDeclined;
}

/// Пользователь не разрешил передать данные ИИ — ничего не отправлено. Это не ошибка: экраны просто
/// останавливаются, без «Try again».
class AiConsentDeclined implements Exception {
  const AiConsentDeclined();

  @override
  String toString() => 'AiConsentDeclined: the user did not allow sharing chats with AI';
}
