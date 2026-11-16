import 'package:dating_assistant/transport/api_request.dart';

/// Транспорт, через который сервисы ходят в API (реализация — RestApiTransport).
///
/// Сервисы знают только этот интерфейс, а реализацию выбирает Injector.
abstract interface class ApiTransport {
  /// Выполняет [request] и возвращает тело ответа.
  ///
  /// Договорённость с сервером: ответ всегда JSON-объект, пустой ответ — `{}`.
  /// При неудаче бросает NetworkError.
  Future<Map<String, dynamic>> callServerApi(ApiRequest request);
}
