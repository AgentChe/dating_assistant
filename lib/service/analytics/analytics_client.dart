import 'package:amplitude_flutter/amplitude.dart';
import 'package:amplitude_flutter/configuration.dart';
import 'package:amplitude_flutter/events/base_event.dart';

/// Куда уходят события — Amplitude. Сервис знает только этот интерфейс, а не плагин.
abstract interface class AnalyticsClient {
  void start(String apiKey);

  Future<void> track(String event, Map<String, Object?> properties);

  Future<void> setUserId(String userId);
}

/// Amplitude через плагин amplitude_flutter. События можно отправлять, пока SDK ещё запускается:
/// он копит их и шлёт пачками.
class AmplitudeAnalyticsClient implements AnalyticsClient {
  Amplitude? _amplitude;

  @override
  void start(String apiKey) => _amplitude ??= Amplitude(Configuration(apiKey: apiKey));

  @override
  Future<void> track(String event, Map<String, Object?> properties) async =>
      _amplitude?.track(BaseEvent(event, eventProperties: properties));

  @override
  Future<void> setUserId(String userId) async => _amplitude?.setUserId(userId);
}
