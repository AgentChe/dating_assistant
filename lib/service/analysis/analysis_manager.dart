import 'dart:typed_data';

import 'package:dating_assistant/service/analysis/model/chat_breakdown.dart';
import 'package:dating_assistant/service/analysis/request/analyze_screenshot_request.dart';
import 'package:dating_assistant/service/usage/usage_mediator.dart';
import 'package:dating_assistant/transport/api_transport.dart';
import 'package:dating_assistant/transport/network_error.dart';

/// Разбор переписки (аналог XxxManager из Swift-проектов). Сам разбор делает нейросеть на нашем сервере.
class AnalysisManager {
  AnalysisManager(this._transport, this._usageMediator);

  /// Статус ответа, когда бесплатные генерации на этой неделе кончились.
  static const generationLimitStatus = 402;

  final ApiTransport _transport;

  final UsageMediator _usageMediator;

  /// Бросает NetworkError; со статусом [generationLimitStatus] — нужен Cue Plus.
  Future<ChatBreakdown> analyzeScreenshot(Uint8List screenshot) async {
    final json = await _transport.callServerApi(AnalyzeScreenshotRequest(screenshot));
    _usageMediator.notifyGenerationUsed();
    return ChatBreakdown.fromJson(json);
  }

  static bool isGenerationLimit(Object error) => error is NetworkError && error.statusCode == generationLimitStatus;
}
