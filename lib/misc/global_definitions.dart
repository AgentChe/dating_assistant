/// Глобальные настройки приложения (аналог GlobalDefinitions из Swift-проектов).
///
/// Адрес сервера можно переопределить при запуске: `flutter run --dart-define=API_BASE_URL=http://localhost:8080`.
abstract final class GlobalDefinitions {
  /// Адрес нашего API — сервер из server/ на машине команды. sslip.io — временный адрес, пока нет своего домена.
  static const apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://cue.192-81-217-92.sslip.io',
  );

  /// OtterScale — аналитика и подписки, как в Swift-приложениях.
  static const otterScaleHost = 'https://api.korrekted.com';

  /// Ключ приложения в OtterScale. Пустой — SDK не запускается.
  static const otterScaleApiKey = 'ghHHSVnIdVYu1er4';

  /// Amplitude — общий проект для приложений студии, как в Swift-приложениях: ключ один,
  /// а приложение различает свойство `app` у каждого события.
  static const amplitudeApiKey = '0d810afcbd45c0b58a5ed6cd272acfa';

  /// Метка приложения в Amplitude (как DOG_TRAINING, WALL_PILATES в Swift-приложениях).
  static const applicationTag = 'DATING_ASSISTANT';

  /// Годовая подписка Cue Plus — одинаковый id в App Store и Google Play.
  // TODO: вписать id годовой подписки, когда создадим продукт в App Store.
  static const paygateYearlyId = '';

  /// Недельная подписка Cue Plus.
  // TODO: вписать id недельной подписки, когда создадим продукт в App Store.
  static const paygateWeeklyId = '';

  static const termsOfServiceUrl = 'https://appdilla.com/terms';

  static const privacyPolicyUrl = 'https://appdilla.com/policy';

  /// Управление подписками в App Store — кнопка «Manage subscription» в профиле.
  static const appStoreSubscriptionsUrl = 'https://apps.apple.com/account/subscriptions';

  static const googlePlaySubscriptionsUrl = 'https://play.google.com/store/account/subscriptions';
}
