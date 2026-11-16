import 'package:dating_assistant/service/analytics/analytics_client.dart';
import 'package:dating_assistant/service/analytics/analytics_manager.dart';

/// Аналитика без Amplitude: запоминает имена событий.
class FakeAnalyticsManager implements AnalyticsManager {
  final events = <String>[];

  @override
  Future<void> start() async {}

  @override
  void logEvent(String name, [Map<String, Object?> properties = const {}]) => events.add(name);

  @override
  void dispose() {}
}

/// Amplitude без плагина: запоминает события и user id.
class FakeAnalyticsClient implements AnalyticsClient {
  String? apiKey;

  final events = <(String, Map<String, Object?>)>[];

  final userIds = <String>[];

  @override
  void start(String apiKey) => this.apiKey = apiKey;

  @override
  Future<void> track(String event, Map<String, Object?> properties) async => events.add((event, properties));

  @override
  Future<void> setUserId(String userId) async => userIds.add(userId);
}
