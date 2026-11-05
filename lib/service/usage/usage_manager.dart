import 'package:dating_assistant/service/usage/model/usage.dart';
import 'package:dating_assistant/service/usage/request/get_usage_request.dart';
import 'package:dating_assistant/transport/api_transport.dart';

/// Лимиты бесплатного плана (аналог XxxManager из Swift-проектов). Генерации считает сервер:
/// клиенту нельзя доверить, сколько бесплатных ответов осталось.
class UsageManager {
  UsageManager(this._transport);

  final ApiTransport _transport;

  Future<Usage> obtainUsage() async => Usage.fromJson(await _transport.callServerApi(const GetUsageRequest()));
}
