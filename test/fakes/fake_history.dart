import 'package:dating_assistant/service/analysis/analysis_manager.dart';
import 'package:dating_assistant/service/coach/coach_manager.dart';
import 'package:dating_assistant/service/history/history_manager.dart';
import 'package:dating_assistant/service/history/model/history_item.dart';
import 'package:dating_assistant/service/opening_line/opening_line_manager.dart';
import 'package:dating_assistant/service/usage/usage_mediator.dart';
import 'package:dating_assistant/transport/api_transport.dart';
import 'package:dating_assistant/transport/mock/mock_api_transport.dart';
import 'package:dating_assistant/transport/mock/mock_database.dart';
import 'package:dating_assistant/transport/mock/mock_server.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fake_profile.dart';

/// Все менеджеры на одном мок-сервере без задержек: история видит то, что создали другие фичи.
typedef MockBackend = ({
  HistoryManager history,
  AnalysisManager analysis,
  CoachManager coach,
  OpeningLineManager openingLines,
  ApiTransport transport,
  MockDatabase database,
  UsageMediator usageMediator,
});

Future<MockBackend> mockBackend() async {
  final profileManager = await fakeProfileManager();
  final preferences = await SharedPreferencesWithCache.create(cacheOptions: const SharedPreferencesWithCacheOptions());
  final database = MockDatabase(preferences);
  final usageMediator = UsageMediator();
  final transport = MockApiTransport(
    server: MockServer(database, generationTime: Duration.zero),
    latency: Duration.zero,
  );
  return (
    history: HistoryManager(transport),
    analysis: AnalysisManager(transport, usageMediator),
    coach: CoachManager(transport, profileManager, usageMediator),
    openingLines: OpeningLineManager(transport, profileManager, usageMediator),
    transport: transport,
    database: database,
    usageMediator: usageMediator,
  );
}

/// История без сервера: по очереди отдаёт заданное в тесте — список или ошибку.
class FakeHistoryManager implements HistoryManager {
  FakeHistoryManager(this.results);

  final List<Object> results;

  var loads = 0;

  @override
  Future<List<HistoryItem>> obtainHistory() async {
    loads++;
    return switch (results.length > 1 ? results.removeAt(0) : results.first) {
      final List<HistoryItem> items => items,
      final error => throw error,
    };
  }
}
