/// Глобальные настройки приложения (аналог GlobalDefinitions из Swift-проектов).
///
/// Значения можно переопределить при запуске:
/// `flutter run --dart-define=USE_MOCKS=false --dart-define=API_BASE_URL=http://localhost:8080`
abstract final class GlobalDefinitions {
  /// Пока сервера нет, приложение работает на моках (transport/mock).
  static const useMocks = bool.fromEnvironment('USE_MOCKS', defaultValue: true);

  /// Адрес нашего API.
  static const apiBaseUrl = String.fromEnvironment('API_BASE_URL', defaultValue: 'http://localhost:8080');

  /// OtterScale — аналитика и подписки, как в Swift-приложениях.
  static const otterScaleHost = 'https://api.korrekted.com';

  /// Ключ приложения в OtterScale. Пока он пустой, SDK не запускается.
  static const otterScaleApiKey = '';

  /// Годовая подписка Cue Plus — одинаковый id в App Store и Google Play.
  // TODO: вписать id годовой подписки, когда создадим продукт в App Store.
  static const paygateYearlyId = '';

  /// Недельная подписка Cue Plus.
  // TODO: вписать id недельной подписки, когда создадим продукт в App Store.
  static const paygateWeeklyId = '';

  // TODO: вписать ссылку на условия использования.
  static const termsOfServiceUrl = '';

  // TODO: вписать ссылку на политику конфиденциальности.
  static const privacyPolicyUrl = '';
}
