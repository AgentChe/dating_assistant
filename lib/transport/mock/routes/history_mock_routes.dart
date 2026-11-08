import 'package:dating_assistant/transport/mock/mock_database.dart';
import 'package:dating_assistant/transport/mock/mock_request.dart';
import 'package:dating_assistant/transport/mock/routes/analysis_mock_routes.dart';
import 'package:dating_assistant/transport/mock/routes/coach_mock_routes.dart';
import 'package:dating_assistant/transport/mock/routes/opening_line_mock_routes.dart';

/// История: разборы, разговоры с коучем и сессии первых фраз — новые сверху, без пагинации.
/// Каждый домен сам знает, как выглядит его запись: история только собирает их вместе.
class HistoryMockRoutes {
  HistoryMockRoutes(this._database);

  final MockDatabase _database;

  Map<String, MockHandler> get routes => {'GET /api/v1/history': _history};

  Map<String, dynamic> _history(MockRequest request) {
    final items = [
      ...AnalysisMockRoutes.historyItems(_database),
      ...CoachMockRoutes.historyItems(_database),
      ...OpeningLineMockRoutes.historyItems(_database),
    ]..sort((first, second) => (second['updated_at'] as String).compareTo(first['updated_at'] as String));
    return {'items': items};
  }
}
