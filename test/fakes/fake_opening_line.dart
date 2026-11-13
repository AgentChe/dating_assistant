import 'package:dating_assistant/service/opening_line/opening_line_manager.dart';
import 'package:dating_assistant/service/profile/profile_manager.dart';
import 'package:dating_assistant/service/usage/usage_manager.dart';
import 'package:dating_assistant/service/usage/usage_mediator.dart';
import 'package:dating_assistant/transport/mock/mock_api_transport.dart';
import 'package:dating_assistant/transport/mock/mock_server.dart';

import 'fake_profile.dart';
import 'fake_usage.dart';

/// Первые фразы на моках без задержек, с профилем из онбординга. Счётчик генераций — в памяти.
typedef MockOpeningLines = ({
  OpeningLineManager manager,
  ProfileManager profileManager,
  UsageManager usageManager,
  UsageMediator usageMediator,
});

Future<MockOpeningLines> mockOpeningLines() async {
  final profileManager = await fakeProfileManager();
  final usageMediator = UsageMediator();
  final usageManager = memoryUsageManager(usageMediator: usageMediator);
  final transport = MockApiTransport(server: MockServer(generationTime: Duration.zero), latency: Duration.zero);
  return (
    manager: OpeningLineManager(transport, profileManager, usageManager),
    profileManager: profileManager,
    usageManager: usageManager,
    usageMediator: usageMediator,
  );
}
