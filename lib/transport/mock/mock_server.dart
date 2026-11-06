import 'package:dating_assistant/transport/api_request.dart';
import 'package:dating_assistant/transport/mock/mock_database.dart';
import 'package:dating_assistant/transport/mock/mock_request.dart';
import 'package:dating_assistant/transport/mock/routes/analysis_mock_routes.dart';
import 'package:dating_assistant/transport/mock/routes/opening_line_mock_routes.dart';
import 'package:dating_assistant/transport/mock/routes/usage_mock_routes.dart';
import 'package:dating_assistant/transport/network_error.dart';

/// Фейковый сервер внутри приложения: находит обработчик под запрос.
///
/// Обработчики работают с «сырым» JSON, как настоящий бэкенд, поэтому моки —
/// это контракт API, по которому потом напишем сервер.
class MockServer {
  /// [generationTime] — сколько отвечает «нейросеть»; в тестах ноль.
  MockServer(MockDatabase database, {Duration generationTime = const Duration(seconds: 3)})
    : _routes = {
        // Маршруты доменов из transport/mock/routes.
        ...UsageMockRoutes(database).routes,
        ...AnalysisMockRoutes(database, generationTime: generationTime).routes,
        ...OpeningLineMockRoutes(database, generationTime: generationTime).routes,
      };

  /// Маршруты вида `'GET /api/v1/analyses/:id'` → обработчик.
  final Map<String, MockHandler> _routes;

  Future<Map<String, dynamic>> handle({
    required HttpMethod method,
    required String path,
    required Map<String, dynamic> query,
    required Map<String, dynamic> body,
  }) async {
    for (final MapEntry(key: route, value: handler) in _routes.entries) {
      final params = _match(route, method, path);
      if (params != null) {
        return handler(MockRequest(params: params, query: query, body: body));
      }
    }
    throw NetworkError(
      NetworkErrorCode.logical,
      statusCode: 404,
      message: 'No mock for ${method.name.toUpperCase()} $path',
    );
  }

  /// Параметры пути, если запрос подходит под маршрут, иначе null.
  Map<String, String>? _match(String route, HttpMethod method, String path) {
    final [routeMethod, routePath] = route.split(' ');
    if (routeMethod != method.name.toUpperCase()) return null;

    final routeSegments = Uri.parse(routePath).pathSegments;
    final segments = Uri.parse(path).pathSegments;
    if (routeSegments.length != segments.length) return null;

    final params = <String, String>{};
    for (var i = 0; i < segments.length; i++) {
      if (routeSegments[i].startsWith(':')) {
        params[routeSegments[i].substring(1)] = segments[i];
      } else if (routeSegments[i] != segments[i]) {
        return null;
      }
    }
    return params;
  }
}
