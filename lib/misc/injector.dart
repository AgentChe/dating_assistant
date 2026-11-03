import 'package:dating_assistant/misc/global_definitions.dart';
import 'package:dating_assistant/service/profile/profile_manager.dart';
import 'package:dating_assistant/service/session/session_manager.dart';
import 'package:dating_assistant/transport/api_transport.dart';
import 'package:dating_assistant/transport/mock/mock_api_transport.dart';
import 'package:dating_assistant/transport/mock/mock_database.dart';
import 'package:dating_assistant/transport/mock/mock_server.dart';
import 'package:dating_assistant/transport/rest_api_transport.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Сборка зависимостей — единственное место, где решается, какие реализации
/// использует приложение (моки или настоящий сервер).
///
/// ViewModel по умолчанию берут менеджеры отсюда, а в тестах им можно передать
/// свои реализации через конструктор.
final class Injector {
  Injector._(this._preferences);

  static Injector? _shared;

  static Injector get shared => _shared ?? (throw StateError('Call Injector.configure() before runApp()'));

  /// Вызывается один раз в main() до runApp().
  static Future<void> configure() async {
    final preferences = await SharedPreferencesWithCache.create(
      cacheOptions: const SharedPreferencesWithCacheOptions(),
    );
    _shared = Injector._(preferences);
  }

  final SharedPreferencesWithCache _preferences;

  late final sessionManager = SessionManager(_preferences);

  late final ApiTransport transport = GlobalDefinitions.useMocks
      ? MockApiTransport(server: MockServer(MockDatabase(_preferences)))
      : RestApiTransport(baseUrl: GlobalDefinitions.apiBaseUrl, defaultHeaders: () => sessionManager.authHeaders);

  late final profileManager = ProfileManager(transport: transport, sessionManager: sessionManager);
}
