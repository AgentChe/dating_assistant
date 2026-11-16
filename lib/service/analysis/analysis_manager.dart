import 'dart:typed_data';

import 'package:dating_assistant/service/analysis/model/chat_breakdown.dart';
import 'package:dating_assistant/service/analysis/request/analyze_screenshot_request.dart';
import 'package:dating_assistant/service/consent/ai_consent_manager.dart';
import 'package:dating_assistant/service/usage/usage_manager.dart';
import 'package:dating_assistant/transport/api_transport.dart';

/// Разбор переписки (аналог XxxManager из Swift-проектов). Сам разбор делает нейросеть на нашем сервере,
/// а хранит его только история на устройстве.
class AnalysisManager {
  AnalysisManager(this._transport, this._usageManager, this._consentManager);

  final ApiTransport _transport;

  final UsageManager _usageManager;

  final AiConsentManager _consentManager;

  /// Согласие на ИИ — до галереи: выбранный скриншот сразу уходит на разбор. Отказ — AiConsentDeclined.
  Future<void> ensureConsent() => _consentManager.ensureGranted();

  /// Бросает NetworkError; кончились бесплатные генерации — GenerationLimitReached, без согласия на ИИ —
  /// AiConsentDeclined; оба — до запроса к серверу.
  Future<ChatBreakdown> analyzeScreenshot(Uint8List screenshot) async {
    await _usageManager.checkLimit();
    await _consentManager.ensureGranted();
    final json = await _transport.callServerApi(AnalyzeScreenshotRequest(screenshot));
    final breakdown = ChatBreakdown.fromJson(json);
    await _usageManager.recordGeneration();
    return breakdown;
  }
}
