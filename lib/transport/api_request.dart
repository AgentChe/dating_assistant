/// HTTP-метод запроса.
enum HttpMethod { get, post, put, patch, delete }

/// Описание запроса к серверу (аналог APIRequestBody из Swift-проектов).
///
/// Каждый эндпоинт — отдельный класс в `service/<домен>/request/`, который
/// переопределяет только то, что отличается от значений по умолчанию.
abstract class ApiRequest {
  const ApiRequest();

  /// Путь относительно базового адреса API, например `/api/v1/profile`.
  String get path;

  HttpMethod get method => HttpMethod.get;

  /// Query-параметры (`?key=value`).
  Map<String, dynamic>? get query => null;

  /// Тело запроса, уходит на сервер как JSON.
  Map<String, dynamic>? get body => null;

  /// Дополнительные заголовки. Общие (авторизацию) добавляет транспорт.
  Map<String, String>? get headers => null;

  @override
  String toString() => '${method.name.toUpperCase()} $path';
}
