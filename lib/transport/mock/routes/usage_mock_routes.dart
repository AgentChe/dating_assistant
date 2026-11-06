import 'package:dating_assistant/transport/mock/mock_database.dart';
import 'package:dating_assistant/transport/mock/mock_request.dart';

/// Лимиты бесплатного плана: 3 генерации в неделю, с понедельника счёт заново.
///
/// Генерации засчитывают маршруты, которые обращаются к нейросети ([consumeGeneration]).
/// Настоящий сервер узнаёт о подписке через OtterScale; мок считает всех пользователей бесплатными.
class UsageMockRoutes {
  UsageMockRoutes(this._database);

  /// Бесплатных генераций в неделю — как в сравнении планов на пейгейте.
  static const freeGenerationsPerWeek = 3;

  static const _key = 'usage';

  final MockDatabase _database;

  Map<String, MockHandler> get routes => {'GET /api/v1/usage': _usage};

  /// Засчитывает генерацию; false — бесплатные на этой неделе кончились.
  static Future<bool> consumeGeneration(MockDatabase database) async {
    final used = _usedThisWeek(database);
    if (used >= freeGenerationsPerWeek) return false;

    await database.write(_key, {'week': _currentWeek(), 'generations_used': used + 1});
    return true;
  }

  Map<String, dynamic> _usage(MockRequest request) => {
    'generations': {'used': _usedThisWeek(_database), 'limit': freeGenerationsPerWeek},
  };

  static int _usedThisWeek(MockDatabase database) {
    final saved = database.read(_key);
    return saved != null && saved['week'] == _currentWeek() ? saved['generations_used'] as int : 0;
  }

  /// Понедельник текущей недели: «2026-11-02».
  static String _currentWeek() {
    final now = DateTime.now();
    final monday = DateTime(now.year, now.month, now.day - (now.weekday - DateTime.monday));
    return monday.toIso8601String().substring(0, 10);
  }
}
