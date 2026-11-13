import 'dart:typed_data';

import 'package:dating_assistant/service/analysis/model/chat_breakdown.dart';
import 'package:dating_assistant/service/analysis/request/analyze_screenshot_request.dart';
import 'package:dating_assistant/service/usage/usage_manager.dart';
import 'package:dating_assistant/transport/api_transport.dart';

/// Разбор переписки (аналог XxxManager из Swift-проектов). Сам разбор делает нейросеть на нашем сервере,
/// а хранит его только история на устройстве.
class AnalysisManager {
  AnalysisManager(this._transport, this._usageManager);

  final ApiTransport _transport;

  final UsageManager _usageManager;

  /// Бросает NetworkError; кончились бесплатные генерации — GenerationLimitReached, до запроса к серверу.
  Future<ChatBreakdown> analyzeScreenshot(Uint8List screenshot) async {
    await _usageManager.checkLimit();
    final json = await _transport.callServerApi(AnalyzeScreenshotRequest(screenshot));
    final breakdown = ChatBreakdown.fromJson(json);
    await _usageManager.recordGeneration();
    return breakdown;
  }
}
