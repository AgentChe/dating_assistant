import 'dart:async';

/// Запрос так, как его видит фейковый сервер.
class MockRequest {
  const MockRequest({required this.params, required this.query, required this.body});

  /// Параметры пути: для маршрута `/api/v1/analyses/:id` → `{'id': '...'}`.
  final Map<String, String> params;

  final Map<String, dynamic> query;

  final Map<String, dynamic> body;
}

/// Обработчик эндпоинта: возвращает JSON-ответ или бросает NetworkError.
typedef MockHandler = FutureOr<Map<String, dynamic>> Function(MockRequest request);
