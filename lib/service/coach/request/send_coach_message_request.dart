import 'dart:convert';
import 'dart:typed_data';

import 'package:dating_assistant/service/coach/model/coach_tone.dart';
import 'package:dating_assistant/service/profile/model/profile.dart';
import 'package:dating_assistant/service/profile/model/spice_level.dart';
import 'package:dating_assistant/transport/api_request.dart';

/// Сообщение коучу — то, что пользователь написал, переписка, которую он показал, или и то и другое.
/// Без [conversationId] сервер начинает новый разговор.
class SendCoachMessageRequest extends ApiRequest {
  const SendCoachMessageRequest({
    this.conversationId,
    this.text,
    required this.tone,
    required this.spice,
    this.you,
    this.analysisId,
    this.chatScreenshot,
  });

  final String? conversationId;

  final String? text;

  final CoachTone tone;

  /// Острота готовых сообщений — та, что по умолчанию в профиле.
  final SpiceLevel spice;

  /// Ответы пользователя с онбординга: под них нейросеть подстраивает голос.
  final Profile? you;

  /// Разбор переписки, с которого открыли коуча («Get the next message»).
  final String? analysisId;

  /// JPEG переписки — сервер прочитает её и вернёт, что понял, в `chat`. Картинку он не хранит.
  final Uint8List? chatScreenshot;

  @override
  String get path => '/api/v1/coach/messages';

  @override
  HttpMethod get method => HttpMethod.post;

  @override
  Map<String, dynamic> get body {
    final screenshot = chatScreenshot;
    return {
      'conversation_id': ?conversationId,
      'text': ?text,
      'tone': tone.name,
      'spice': spice.name,
      'you': ?you?.toRequestJson(),
      'analysis_id': ?analysisId,
      if (screenshot != null) 'chat_screenshot': base64Encode(screenshot),
    };
  }
}
