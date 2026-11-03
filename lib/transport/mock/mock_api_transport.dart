import 'dart:convert';

import 'package:dating_assistant/transport/api_request.dart';
import 'package:dating_assistant/transport/api_transport.dart';
import 'package:dating_assistant/transport/mock/mock_server.dart';

/// Транспорт на моках: вместо сети отправляет запросы в фейковый сервер [MockServer].
class MockApiTransport implements ApiTransport {
  MockApiTransport({required MockServer server, this.latency = const Duration(milliseconds: 600)}) : _server = server;

  final MockServer _server;

  /// Имитация сети, чтобы на моках были видны лоадеры.
  final Duration latency;

  @override
  Future<Map<String, dynamic>> callServerApi(ApiRequest request) async {
    await Future<void>.delayed(latency);
    // Гоняем данные через JSON, как при настоящем запросе: в мок уходит только то,
    // что сериализуется, а модели парсят ровно то, что вернул бы сервер.
    final response = await _server.handle(
      method: request.method,
      path: request.path,
      query: _viaJson(request.query),
      body: _viaJson(request.body),
    );
    return _viaJson(response);
  }

  Map<String, dynamic> _viaJson(Map<String, dynamic>? json) =>
      jsonDecode(jsonEncode(json ?? const <String, dynamic>{})) as Map<String, dynamic>;
}
