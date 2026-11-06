import 'dart:convert';
import 'dart:typed_data';

import 'package:dating_assistant/service/analysis/analysis_manager.dart';
import 'package:dating_assistant/service/analysis/model/chat_breakdown.dart';
import 'package:dating_assistant/service/usage/usage_mediator.dart';
import 'package:dating_assistant/transport/mock/mock_api_transport.dart';
import 'package:dating_assistant/transport/mock/mock_database.dart';
import 'package:dating_assistant/transport/mock/mock_server.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

/// Настоящая картинка 1×1 PNG: Image.memory в тестах должен её декодировать.
final fakeScreenshot = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==',
);

/// AnalysisManager на моках без задержек — для разбора из примера.
Future<AnalysisManager> mockAnalysisManager({UsageMediator? usageMediator}) async {
  SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
  final preferences = await SharedPreferencesWithCache.create(cacheOptions: const SharedPreferencesWithCacheOptions());
  final server = MockServer(MockDatabase(preferences), generationTime: Duration.zero);
  return AnalysisManager(MockApiTransport(server: server, latency: Duration.zero), usageMediator ?? UsageMediator());
}

/// Разбор переписки с Nika из макета.
Future<ChatBreakdown> exampleBreakdown() async => (await mockAnalysisManager()).analyzeScreenshot(fakeScreenshot);

/// Разбор без сервера: отдаёт или бросает то, что задано в тесте, по очереди.
class FakeAnalysisManager implements AnalysisManager {
  FakeAnalysisManager(this.results);

  /// ChatBreakdown — успех, всё остальное бросается как ошибка.
  final List<Object> results;

  final screenshots = <Uint8List>[];

  @override
  Future<ChatBreakdown> analyzeScreenshot(Uint8List screenshot) async {
    screenshots.add(screenshot);
    final result = results.removeAt(0);
    if (result is ChatBreakdown) return result;
    throw result;
  }
}
