import 'dart:convert';
import 'dart:typed_data';

import 'package:dating_assistant/service/opening_line/model/opening_line.dart';
import 'package:dating_assistant/service/profile/model/profile.dart';
import 'package:dating_assistant/service/profile/model/spice_level.dart';
import 'package:dating_assistant/transport/api_request.dart';

/// Первая фраза для мэтча. Без анкеты и подробностей — просто фраза под голос пользователя.
/// Без [sessionId] сервер начинает новую сессию — в истории она одна запись, сколько фраз ни попроси.
class GenerateOpeningLineRequest extends ApiRequest {
  const GenerateOpeningLineRequest({
    required this.spice,
    this.sessionId,
    this.you,
    this.match,
    this.profileScreenshot,
    this.previousLines = const [],
  });

  final SpiceLevel spice;

  /// Сессия, в которой просят следующую фразу («Another one»).
  final String? sessionId;

  /// Ответы пользователя с онбординга: под них нейросеть подстраивает голос.
  final Profile? you;

  final MatchDetails? match;

  /// JPEG анкеты — сервер прочитает её и вернёт, что понял, в `match`.
  final Uint8List? profileScreenshot;

  /// Уже предложенные фразы — чтобы не повторяться.
  final List<String> previousLines;

  @override
  String get path => '/api/v1/opening-lines';

  @override
  HttpMethod get method => HttpMethod.post;

  @override
  Map<String, dynamic> get body {
    final match = this.match;
    final screenshot = profileScreenshot;
    return {
      'spice': spice.name,
      'session_id': ?sessionId,
      'you': ?you?.toRequestJson(),
      if (match != null && !match.isEmpty) 'match': match.toJson(),
      if (screenshot != null) 'profile_screenshot': base64Encode(screenshot),
      if (previousLines.isNotEmpty) 'previous_lines': previousLines,
    };
  }
}
