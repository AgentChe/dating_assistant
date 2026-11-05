import 'package:dating_assistant/transport/mock/mock_database.dart';
import 'package:dating_assistant/transport/mock/mock_request.dart';

/// Лимиты бесплатного плана. Генерации будут засчитывать маршруты коуча, первых фраз и разбора чатов.
class UsageMockRoutes {
  UsageMockRoutes(this._database);

  /// Бесплатных генераций в неделю — как в сравнении планов на пейгейте.
  static const freeGenerationsPerWeek = 3;

  static const _key = 'usage';

  final MockDatabase _database;

  Map<String, MockHandler> get routes => {'GET /api/v1/usage': _usage};

  Map<String, dynamic> _usage(MockRequest request) => {
    'generations': {'used': _database.read(_key)?['generations_used'] ?? 0, 'limit': freeGenerationsPerWeek},
  };
}
