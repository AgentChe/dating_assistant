import 'package:dating_assistant/misc/global_definitions.dart';
import 'package:dating_assistant/service/analysis/analysis_manager.dart';
import 'package:dating_assistant/service/analytics/analytics_manager.dart';
import 'package:dating_assistant/service/coach/coach_manager.dart';
import 'package:dating_assistant/service/consent/ai_consent_manager.dart';
import 'package:dating_assistant/service/connectivity/connectivity_manager.dart';
import 'package:dating_assistant/service/history/history_manager.dart';
import 'package:dating_assistant/service/history/history_mediator.dart';
import 'package:dating_assistant/service/opening_line/opening_line_manager.dart';
import 'package:dating_assistant/service/profile/profile_manager.dart';
import 'package:dating_assistant/service/purchase/purchase_manager.dart';
import 'package:dating_assistant/service/session/session_manager.dart';
import 'package:dating_assistant/service/usage/usage_manager.dart';
import 'package:dating_assistant/service/usage/usage_mediator.dart';
import 'package:dating_assistant/service/usage/usage_storage.dart';
import 'package:dating_assistant/transport/api_transport.dart';
import 'package:dating_assistant/transport/rest_api_transport.dart';
import 'package:hive_ce/hive_ce.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Сборка зависимостей (аналог lazy var manager в Swift-проектах): ViewModel по умолчанию берут менеджеры отсюда,
/// а через конструктор им можно передать другие.
final class Injector {
  Injector._(this._preferences, this._historyBox);

  static Injector? _shared;

  static Injector get shared => _shared ?? (throw StateError('Call Injector.configure() before runApp()'));

  /// Вызывается один раз в main() до runApp().
  static Future<void> configure() async {
    final preferences = await SharedPreferencesWithCache.create(
      cacheOptions: const SharedPreferencesWithCacheOptions(),
    );
    _shared = Injector._(preferences, await _openHistory());
  }

  /// История лежит в Application Support: её не видно в «Файлах», и система не чистит её, как кэш.
  static Future<Box<String>> _openHistory() async {
    Hive.init((await getApplicationSupportDirectory()).path);
    return Hive.openBox<String>('history');
  }

  final SharedPreferencesWithCache _preferences;

  final Box<String> _historyBox;

  late final sessionManager = SessionManager(
    host: GlobalDefinitions.otterScaleHost,
    apiKey: GlobalDefinitions.otterScaleApiKey,
  );

  late final profileManager = ProfileManager(_preferences);

  late final analyticsManager = AnalyticsManager(sessionManager: sessionManager, preferences: _preferences);

  late final purchaseManager = PurchaseManager(sessionManager: sessionManager);

  late final usageManager = UsageManager(DeviceUsageStorage(_preferences), sessionManager, usageMediator);

  late final usageMediator = UsageMediator();

  late final historyMediator = HistoryMediator();

  late final historyManager = HistoryManager(_historyBox, historyMediator);

  late final connectivityManager = ConnectivityManager();

  /// Согласие на передачу данных ИИ: без него менеджеры генераций ничего не отправляют.
  late final aiConsentManager = AiConsentManager(_preferences);

  late final analysisManager = AnalysisManager(transport, usageManager, aiConsentManager);

  late final openingLineManager = OpeningLineManager(transport, profileManager, usageManager, aiConsentManager);

  late final coachManager = CoachManager(transport, profileManager, usageManager, aiConsentManager);

  /// Транспорт к нашему серверу (server/).
  late final ApiTransport transport = RestApiTransport(baseUrl: GlobalDefinitions.apiBaseUrl);
}
