import 'package:dating_assistant/transport/api_request.dart';

/// Транспорт, через который сервисы ходят в API.
///
/// Реализации: RestApiTransport — настоящий сервер, MockApiTransport — моки.
/// Сервисы знают только этот интерфейс, поэтому переход с моков на сервер —
/// замена реализации в одном месте (Injector).
abstract interface class ApiTransport {
  /// Выполняет [request] и возвращает тело ответа.
  ///
  /// Договорённость с сервером: ответ всегда JSON-объект, пустой ответ — `{}`.
  /// При неудаче бросает NetworkError.
  Future<Map<String, dynamic>> callServerApi(ApiRequest request);
}
