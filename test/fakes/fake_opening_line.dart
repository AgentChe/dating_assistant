import 'package:dating_assistant/service/opening_line/opening_line_manager.dart';
import 'package:dating_assistant/service/profile/profile_manager.dart';
import 'package:dating_assistant/service/usage/usage_mediator.dart';
import 'package:dating_assistant/transport/mock/mock_api_transport.dart';
import 'package:dating_assistant/transport/mock/mock_database.dart';
import 'package:dating_assistant/transport/mock/mock_server.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fake_profile.dart';

/// Первые фразы на моках без задержек, с профилем из онбординга.
typedef MockOpeningLines = ({
  OpeningLineManager manager,
  ProfileManager profileManager,
  MockDatabase database,
  UsageMediator usageMediator,
});

Future<MockOpeningLines> mockOpeningLines() async {
  final profileManager = await fakeProfileManager();
  final preferences = await SharedPreferencesWithCache.create(cacheOptions: const SharedPreferencesWithCacheOptions());
  final database = MockDatabase(preferences);
  final usageMediator = UsageMediator();
  final transport = MockApiTransport(
    server: MockServer(database, generationTime: Duration.zero),
    latency: Duration.zero,
  );
  return (
    manager: OpeningLineManager(transport, profileManager, usageMediator),
    profileManager: profileManager,
    database: database,
    usageMediator: usageMediator,
  );
}
