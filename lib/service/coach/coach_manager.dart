import 'dart:typed_data';

import 'package:dating_assistant/service/coach/model/coach_conversation.dart';
import 'package:dating_assistant/service/coach/model/coach_reply.dart';
import 'package:dating_assistant/service/coach/model/coach_tone.dart';
import 'package:dating_assistant/service/coach/request/send_coach_message_request.dart';
import 'package:dating_assistant/service/profile/model/spice_level.dart';
import 'package:dating_assistant/service/profile/profile_manager.dart';
import 'package:dating_assistant/service/usage/usage_manager.dart';
import 'package:dating_assistant/transport/api_transport.dart';

/// Разговор с коучем — фича Dating advice (аналог XxxManager из Swift-проектов). Отвечает нейросеть
/// на нашем сервере. Разговор сервер не помнит: он хранится в истории на устройстве и уходит с каждым сообщением.
class CoachManager {
  CoachManager(this._transport, this._profileManager, this._usageManager);

  final ApiTransport _transport;

  final ProfileManager _profileManager;

  final UsageManager _usageManager;

  /// Каждый ответ коуча — генерация. Бросает NetworkError; кончились бесплатные — GenerationLimitReached,
  /// до запроса к серверу.
  Future<CoachReply> send({
    required CoachConversation conversation,
    String? text,
    required CoachTone tone,
    Uint8List? chatScreenshot,
  }) async {
    await _usageManager.checkLimit();
    final profile = _profileManager.profile;
    final json = await _transport.callServerApi(
      SendCoachMessageRequest(
        text: text,
        tone: tone,
        spice: profile?.spice ?? SpiceLevel.warm,
        you: profile,
        messages: conversation.messages,
        chat: conversation.chat,
        breakdown: conversation.breakdown,
        chatScreenshot: chatScreenshot,
      ),
    );
    final reply = CoachReply.fromJson(json);
    await _usageManager.recordGeneration();
    return reply;
  }
}
