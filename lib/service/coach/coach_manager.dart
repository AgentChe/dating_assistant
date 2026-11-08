import 'dart:typed_data';

import 'package:dating_assistant/service/coach/model/coach_conversation.dart';
import 'package:dating_assistant/service/coach/model/coach_reply.dart';
import 'package:dating_assistant/service/coach/model/coach_tone.dart';
import 'package:dating_assistant/service/coach/request/send_coach_message_request.dart';
import 'package:dating_assistant/service/profile/model/spice_level.dart';
import 'package:dating_assistant/service/profile/profile_manager.dart';
import 'package:dating_assistant/service/usage/usage_mediator.dart';
import 'package:dating_assistant/transport/api_transport.dart';

/// Разговор с коучем — фича Dating advice (аналог XxxManager из Swift-проектов). Отвечает нейросеть
/// на нашем сервере. Разговор сервер не помнит: он хранится в истории на устройстве и уходит с каждым сообщением.
class CoachManager {
  CoachManager(this._transport, this._profileManager, this._usageMediator);

  final ApiTransport _transport;

  final ProfileManager _profileManager;

  final UsageMediator _usageMediator;

  /// Каждый ответ коуча — генерация. Бросает NetworkError; кончились бесплатные — см. UsageManager.isGenerationLimit.
  Future<CoachReply> send({
    required CoachConversation conversation,
    String? text,
    required CoachTone tone,
    Uint8List? chatScreenshot,
  }) async {
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
    _usageMediator.notifyGenerationUsed();
    return CoachReply.fromJson(json);
  }
}
