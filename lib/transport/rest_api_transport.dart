import 'package:dating_assistant/transport/api_request.dart';
import 'package:dating_assistant/transport/api_transport.dart';
import 'package:dating_assistant/transport/network_error.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Транспорт к нашему серверу на базе dio (аналог RestAPITransport).
class RestApiTransport implements ApiTransport {
  RestApiTransport({required String baseUrl, this._defaultHeaders})
    : _dio = Dio(
        BaseOptions(
          baseUrl: baseUrl,
          connectTimeout: const Duration(seconds: 30),
          sendTimeout: const Duration(seconds: 60),
          receiveTimeout: const Duration(seconds: 60),
        ),
      ) {
    if (kDebugMode) {
      _dio.interceptors.add(
        LogInterceptor(requestBody: true, responseBody: true, logPrint: (log) => debugPrint('$log')),
      );
    }
  }

  final Dio _dio;

  /// Общие заголовки (например, токен сессии). Вызывается перед каждым запросом,
  /// поэтому всегда отдаёт актуальные значения.
  final Map<String, String> Function()? _defaultHeaders;

  @override
  Future<Map<String, dynamic>> callServerApi(ApiRequest request) async {
    final Response<Object?> response;
    try {
      response = await _dio.request<Object?>(
        request.path,
        data: request.body,
        queryParameters: request.query,
        options: Options(
          method: request.method.name.toUpperCase(),
          headers: {...?_defaultHeaders?.call(), ...?request.headers},
        ),
      );
    } on DioException catch (error) {
      throw _map(error);
    }

    return switch (response.data) {
      null || '' => <String, dynamic>{},
      final Map<String, dynamic> json => json,
      _ => throw NetworkError(NetworkErrorCode.invalidResponse, statusCode: response.statusCode),
    };
  }

  NetworkError _map(DioException error) {
    final response = error.response;
    if (response == null) {
      return NetworkError(NetworkErrorCode.serverNotAvailable, underlyingError: error);
    }

    final message = switch (response.data) {
      {'error': {'message': final String message}} => message,
      _ => null,
    };
    return NetworkError(
      NetworkErrorCode.logical,
      statusCode: response.statusCode,
      message: message,
      underlyingError: error,
    );
  }
}
