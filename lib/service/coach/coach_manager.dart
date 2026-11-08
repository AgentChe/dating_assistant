import 'dart:typed_data';

import 'package:dating_assistant/service/coach/model/coach_reply.dart';
import 'package:dating_assistant/service/coach/model/coach_tone.dart';
import 'package:dating_assistant/service/coach/request/send_coach_message_request.dart';
import 'package:dating_assistant/service/profile/model/spice_level.dart';
import 'package:dating_assistant/service/profile/profile_manager.dart';
import 'package:dating_assistant/service/usage/usage_mediator.dart';
import 'package:dating_assistant/transport/api_transport.dart';

/// Разговор с коучем — фича Dating advice (аналог XxxManager из Swift-проектов). Отвечает нейросеть
/// на нашем сервере; историю разговора хранит сервер, клиент шлёт только новое сообщение.
class CoachManager {
  CoachManager(this._transport, this._profileManager, this._usageMediator);

  final ApiTransport _transport;

  final ProfileManager _profileManager;

  final UsageMediator _usageMediator;

  /// Каждый ответ коуча — генерация. Бросает NetworkError; кончились бесплатные — см. UsageManager.isGenerationLimit.
  Future<CoachReply> send({
    String? conversationId,
    String? text,
    required CoachTone tone,
    String? analysisId,
    Uint8List? chatScreenshot,
  }) async {
    final profile = _profileManager.profile;
    final json = await _transport.callServerApi(
      SendCoachMessageRequest(
        conversationId: conversationId,
        text: text,
        tone: tone,
        spice: profile?.spice ?? SpiceLevel.warm,
        you: profile,
        analysisId: analysisId,
        chatScreenshot: chatScreenshot,
      ),
    );
    _usageMediator.notifyGenerationUsed();
    return CoachReply.fromJson(json);
  }
}
