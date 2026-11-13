import 'dart:convert';
import 'dart:typed_data';

import 'package:dating_assistant/misc/media/screenshot_picker.dart';
import 'package:dating_assistant/service/analysis/analysis_manager.dart';
import 'package:dating_assistant/service/analysis/model/chat_breakdown.dart';
import 'package:dating_assistant/service/usage/usage_mediator.dart';
import 'package:dating_assistant/transport/mock/mock_api_transport.dart';
import 'package:dating_assistant/transport/mock/mock_server.dart';

import 'fake_usage.dart';

/// Настоящая картинка 1×1 PNG: Image.memory в тестах должен её декодировать.
final fakeScreenshot = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==',
);

/// AnalysisManager на моках без задержек — для разбора из примера. Счётчик генераций — в памяти.
Future<AnalysisManager> mockAnalysisManager({UsageMediator? usageMediator}) async => AnalysisManager(
  MockApiTransport(server: MockServer(generationTime: Duration.zero), latency: Duration.zero),
  memoryUsageManager(usageMediator: usageMediator),
);

/// Разбор переписки с Nika из макета.
Future<ChatBreakdown> exampleBreakdown() async => (await mockAnalysisManager()).analyzeScreenshot(fakeScreenshot);

/// Галерея без системного пикера: «выбирает» [screenshot], null — пользователь закрыл галерею.
class FakeScreenshotPicker implements ScreenshotPicker {
  Uint8List? screenshot = fakeScreenshot;

  var picks = 0;

  @override
  Future<Uint8List?> pick() async {
    picks++;
    return screenshot;
  }
}

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
