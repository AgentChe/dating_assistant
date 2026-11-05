import 'package:dating_assistant/service/usage/usage_manager.dart';
import 'package:dating_assistant/transport/mock/mock_api_transport.dart';
import 'package:dating_assistant/transport/mock/mock_database.dart';
import 'package:dating_assistant/transport/mock/mock_server.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  late MockDatabase database;
  late UsageManager usageManager;

  setUp(() async {
    SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
    final preferences = await SharedPreferencesWithCache.create(
      cacheOptions: const SharedPreferencesWithCacheOptions(),
    );
    database = MockDatabase(preferences);
    usageManager = UsageManager(MockApiTransport(server: MockServer(database), latency: Duration.zero));
  });

  test('a new user has all three free generations', () async {
    final usage = await usageManager.obtainUsage();

    expect(usage.used, 0);
    expect(usage.limit, 3);
    expect(usage.left, 3);
  });

  test('counts the generations the server has recorded', () async {
    await database.write('usage', {'generations_used': 2});

    expect((await usageManager.obtainUsage()).left, 1);

    await database.write('usage', {'generations_used': 5});

    expect((await usageManager.obtainUsage()).left, 0);
  });
}
