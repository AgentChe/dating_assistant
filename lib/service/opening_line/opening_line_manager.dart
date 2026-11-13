import 'dart:typed_data';

import 'package:dating_assistant/service/opening_line/model/opening_line.dart';
import 'package:dating_assistant/service/opening_line/request/generate_opening_line_request.dart';
import 'package:dating_assistant/service/profile/model/spice_level.dart';
import 'package:dating_assistant/service/profile/profile_manager.dart';
import 'package:dating_assistant/service/usage/usage_manager.dart';
import 'package:dating_assistant/transport/api_transport.dart';

/// Первые фразы для мэтча (аналог XxxManager из Swift-проектов). Пишет их нейросеть на нашем сервере.
class OpeningLineManager {
  OpeningLineManager(this._transport, this._profileManager, this._usageManager);

  final ApiTransport _transport;

  final ProfileManager _profileManager;

  final UsageManager _usageManager;

  /// Бросает NetworkError; кончились бесплатные генерации — GenerationLimitReached, до запроса к серверу.
  Future<OpeningLine> generate({
    required SpiceLevel spice,
    MatchDetails? match,
    Uint8List? profileScreenshot,
    List<String> previousLines = const [],
  }) async {
    await _usageManager.checkLimit();
    final json = await _transport.callServerApi(
      GenerateOpeningLineRequest(
        spice: spice,
        you: _profileManager.profile,
        match: match,
        profileScreenshot: profileScreenshot,
        previousLines: previousLines,
      ),
    );
    final line = OpeningLine.fromJson(json);
    await _usageManager.recordGeneration();
    return line;
  }
}
