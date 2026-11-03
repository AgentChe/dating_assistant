import 'package:dating_assistant/service/profile/model/dating_goal.dart';
import 'package:dating_assistant/service/profile/model/gender.dart';
import 'package:dating_assistant/service/profile/profile_manager.dart';
import 'package:dating_assistant/service/session/session_manager.dart';
import 'package:dating_assistant/transport/mock/mock_api_transport.dart';
import 'package:dating_assistant/transport/mock/mock_database.dart';
import 'package:dating_assistant/transport/mock/mock_server.dart';
import 'package:dating_assistant/transport/network_error.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  late SessionManager sessionManager;
  late ProfileManager profileManager;

  setUp(() async {
    SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
    final preferences = await SharedPreferencesWithCache.create(
      cacheOptions: const SharedPreferencesWithCacheOptions(),
    );
    sessionManager = SessionManager(preferences);
    profileManager = ProfileManager(
      transport: MockApiTransport(server: MockServer(MockDatabase(preferences)), latency: Duration.zero),
      sessionManager: sessionManager,
    );
  });

  test('create saves the session and obtain returns the same profile', () async {
    expect(sessionManager.isAuthorized, isFalse);

    await profileManager.create(gender: Gender.female, age: 27, datingGoal: DatingGoal.relationship);
    expect(sessionManager.isAuthorized, isTrue);

    final profile = await profileManager.obtain();
    expect(profile.gender, Gender.female);
    expect(profile.age, 27);
    expect(profile.datingGoal, DatingGoal.relationship);
  });

  test('obtain fails with 404 before onboarding', () async {
    await expectLater(
      profileManager.obtain(),
      throwsA(isA<NetworkError>().having((error) => error.statusCode, 'statusCode', 404)),
    );
  });
}
