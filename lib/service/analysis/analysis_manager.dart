import 'dart:typed_data';

import 'package:dating_assistant/service/analysis/model/chat_breakdown.dart';
import 'package:dating_assistant/service/analysis/request/analyze_screenshot_request.dart';
import 'package:dating_assistant/service/usage/usage_mediator.dart';
import 'package:dating_assistant/transport/api_transport.dart';

/// Разбор переписки (аналог XxxManager из Swift-проектов). Сам разбор делает нейросеть на нашем сервере,
/// а хранит его только история на устройстве.
class AnalysisManager {
  AnalysisManager(this._transport, this._usageMediator);

  final ApiTransport _transport;

  final UsageMediator _usageMediator;

  /// Бросает NetworkError; кончились бесплатные генерации — см. UsageManager.isGenerationLimit.
  Future<ChatBreakdown> analyzeScreenshot(Uint8List screenshot) async {
    final json = await _transport.callServerApi(AnalyzeScreenshotRequest(screenshot));
    _usageMediator.notifyGenerationUsed();
    return ChatBreakdown.fromJson(json);
  }
}
