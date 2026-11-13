import 'dart:convert';

import 'package:dating_assistant/service/session/session_manager.dart';
import 'package:dating_assistant/service/usage/model/usage.dart';
import 'package:dating_assistant/service/usage/usage_mediator.dart';
import 'package:dating_assistant/service/usage/usage_storage.dart';
import 'package:flutter/foundation.dart';

/// Бесплатные генерации (аналог XxxManager из Swift-проектов): 3 в неделю на разборы, ответы коуча
/// и первые фразы вместе, с понедельника заново. Сервер о лимите не знает — считает устройство.
///
/// Менеджеры генераций спрашивают [checkLimit] перед запросом и вызывают [recordGeneration] после ответа,
/// поэтому неудачная генерация не тратится. С Cue Plus лимита нет, и генерации не считаются: если подписка
/// кончится, у пользователя будут обычные три бесплатные.
class UsageManager {
  UsageManager(this._storage, this._sessionManager, this._mediator, {DateTime Function()? now})
    : _now = now ?? DateTime.now;

  /// Бесплатных генераций в неделю — как в сравнении планов на пейгейте.
  static const freePerWeek = 3;

  final UsageStorage _storage;

  final SessionManager _sessionManager;

  final UsageMediator _mediator;

  final DateTime Function() _now;

  /// Сколько бесплатных генераций потрачено на этой неделе.
  Future<Usage> obtainUsage() async => Usage(used: await _usedThisWeek(), limit: freePerWeek);

  /// Перед генерацией: бросает [GenerationLimitReached], если бесплатные кончились и Cue Plus нет.
  Future<void> checkLimit() async {
    if (await _sessionManager.hasActiveSubscriptions()) return;
    if ((await obtainUsage()).left == 0) throw const GenerationLimitReached();
  }

  /// Генерация удалась — засчитываем её, если это бесплатная.
  Future<void> recordGeneration() async {
    if (await _sessionManager.hasActiveSubscriptions()) return;
    final used = await _usedThisWeek();
    await _storage.write(jsonEncode({'week': _currentWeek(), 'used': used + 1}));
    _mediator.notifyGenerationUsed();
  }

  /// Генерацию не дали: нужен Cue Plus.
  static bool isGenerationLimit(Object error) => error is GenerationLimitReached;

  Future<int> _usedThisWeek() async {
    try {
      final saved = await _storage.read();
      if (saved == null) return 0;
      final json = jsonDecode(saved) as Map<String, dynamic>;
      return json['week'] == _currentWeek() ? json['used'] as int : 0;
    } catch (error) {
      // Счётчик не прочитать — начинаем неделю заново: лучше лишняя бесплатная генерация, чем закрытая функция.
      debugPrint('UsageManager: cannot read the counter: $error');
      return 0;
    }
  }

  /// Понедельник текущей недели по времени телефона: «2026-11-09».
  String _currentWeek() {
    final now = _now();
    final monday = DateTime(now.year, now.month, now.day - (now.weekday - DateTime.monday));
    return monday.toIso8601String().substring(0, 10);
  }
}

/// Бесплатные генерации на этой неделе кончились — экран предлагает Cue Plus.
class GenerationLimitReached implements Exception {
  const GenerationLimitReached();

  @override
  String toString() => 'GenerationLimitReached: no free generations left this week';
}
