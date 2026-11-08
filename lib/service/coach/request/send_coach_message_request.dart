import 'dart:convert';
import 'dart:typed_data';

import 'package:dating_assistant/service/analysis/model/chat_breakdown.dart';
import 'package:dating_assistant/service/coach/model/attached_chat.dart';
import 'package:dating_assistant/service/coach/model/coach_conversation.dart';
import 'package:dating_assistant/service/coach/model/coach_tone.dart';
import 'package:dating_assistant/service/profile/model/profile.dart';
import 'package:dating_assistant/service/profile/model/spice_level.dart';
import 'package:dating_assistant/transport/api_request.dart';

/// Сообщение коучу — то, что пользователь написал, скриншот переписки или и то и другое.
/// Сервер разговоров не хранит: с сообщением уходит всё, что было в разговоре до него.
class SendCoachMessageRequest extends ApiRequest {
  const SendCoachMessageRequest({
    this.text,
    required this.tone,
    required this.spice,
    this.you,
    this.messages = const [],
    this.chat,
    this.breakdown,
    this.chatScreenshot,
  });

  final String? text;

  final CoachTone tone;

  /// Острота готовых сообщений — та, что по умолчанию в профиле.
  final SpiceLevel spice;

  /// Ответы пользователя с онбординга: под них нейросеть подстраивает голос.
  final Profile? you;

  /// Разговор до этого сообщения, по порядку.
  final List<CoachMessage> messages;

  /// Переписка, о которой разговор: что сервер прочитал на скриншоте раньше или что известно из разбора.
  final AttachedChat? chat;

  /// Разбор переписки, из которого открыли коуча («Get the next message»).
  final ChatBreakdown? breakdown;

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
      'text': ?text,
      'tone': tone.name,
      'spice': spice.name,
      'you': ?you?.toRequestJson(),
      if (messages.isNotEmpty) 'messages': [for (final message in messages) message.toJson()],
      'chat': ?chat?.toJson(),
      'breakdown': ?breakdown?.toJson(),
      if (screenshot != null) 'chat_screenshot': base64Encode(screenshot),
    };
  }
}
