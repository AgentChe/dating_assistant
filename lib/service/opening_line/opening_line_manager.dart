import 'dart:typed_data';

import 'package:dating_assistant/service/opening_line/model/opening_line.dart';
import 'package:dating_assistant/service/opening_line/request/generate_opening_line_request.dart';
import 'package:dating_assistant/service/opening_line/request/get_opening_line_session_request.dart';
import 'package:dating_assistant/service/profile/model/spice_level.dart';
import 'package:dating_assistant/service/profile/profile_manager.dart';
import 'package:dating_assistant/service/usage/usage_mediator.dart';
import 'package:dating_assistant/transport/api_transport.dart';

/// Первые фразы для мэтча (аналог XxxManager из Swift-проектов). Пишет их нейросеть на нашем сервере.
class OpeningLineManager {
  OpeningLineManager(this._transport, this._profileManager, this._usageMediator);

  final ApiTransport _transport;

  final ProfileManager _profileManager;

  final UsageMediator _usageMediator;

  /// Без [sessionId] начинается новая сессия. Бросает NetworkError; кончились бесплатные генерации —
  /// см. UsageManager.isGenerationLimit.
  Future<OpeningLine> generate({
    required SpiceLevel spice,
    String? sessionId,
    MatchDetails? match,
    Uint8List? profileScreenshot,
    List<String> previousLines = const [],
  }) async {
    final json = await _transport.callServerApi(
      GenerateOpeningLineRequest(
        spice: spice,
        sessionId: sessionId,
        you: _profileManager.profile,
        match: match,
        profileScreenshot: profileScreenshot,
        previousLines: previousLines,
      ),
    );
    _usageMediator.notifyGenerationUsed();
    return OpeningLine.fromJson(json);
  }

  /// Последняя фраза сессии из истории — вместе с тем, что известно о мэтче.
  Future<OpeningLine> obtainSession(String sessionId) async =>
      OpeningLine.fromJson(await _transport.callServerApi(GetOpeningLineSessionRequest(sessionId)));
}
