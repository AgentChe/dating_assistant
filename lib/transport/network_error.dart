/// Ошибка сетевого слоя (аналог NetworkError из Swift-проектов).
class NetworkError implements Exception {
  const NetworkError(this.code, {this.statusCode, this.message, this.underlyingError});

  final NetworkErrorCode code;

  /// HTTP-статус, если сервер ответил.
  final int? statusCode;

  /// Сообщение сервера из ответа вида `{"error": {"message": "..."}}`.
  final String? message;

  final Object? underlyingError;

  @override
  String toString() =>
      'NetworkError(${code.name}, status: $statusCode, message: $message, underlying: $underlyingError)';
}

enum NetworkErrorCode {
  /// Сервер не ответил: нет интернета, таймаут, DNS и т.п.
  serverNotAvailable,

  /// Сервер ответил ошибкой (4xx/5xx).
  logical,

  /// Ответ пришёл, но это не JSON-объект.
  invalidResponse,
}
