import 'package:dating_assistant/service/usage/model/usage.dart';
import 'package:dating_assistant/service/usage/request/get_usage_request.dart';
import 'package:dating_assistant/transport/api_transport.dart';
import 'package:dating_assistant/transport/network_error.dart';

/// Лимиты бесплатного плана (аналог XxxManager из Swift-проектов). Генерации считает сервер:
/// клиенту нельзя доверить, сколько бесплатных ответов осталось.
class UsageManager {
  UsageManager(this._transport);

  /// Статус ответа на генерацию, когда бесплатные на этой неделе кончились.
  static const generationLimitStatus = 402;

  final ApiTransport _transport;

  Future<Usage> obtainUsage() async => Usage.fromJson(await _transport.callServerApi(const GetUsageRequest()));

  /// Генерацию не дали: нужен Cue Plus.
  static bool isGenerationLimit(Object error) => error is NetworkError && error.statusCode == generationLimitStatus;
}
