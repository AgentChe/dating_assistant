import 'package:dating_assistant/service/coach/model/attached_chat.dart';
import 'package:dating_assistant/service/coach/model/coach_reply.dart';

/// Сообщение в разговоре с коучем — как его хранит сервер.
class CoachMessage {
  const CoachMessage({required this.isFromCoach, this.text, this.suggestion});

  factory CoachMessage.fromJson(Map<String, dynamic> json) {
    final suggestion = json['suggestion'] as Map<String, dynamic>?;
    return CoachMessage(
      isFromCoach: json['from'] == 'coach',
      text: json['text'] as String?,
      suggestion: suggestion == null ? null : CoachSuggestion.fromJson(suggestion),
    );
  }

  final bool isFromCoach;

  /// null — пользователь только приложил переписку, без слов.
  final String? text;

  /// Что коуч предложил отправить.
  final CoachSuggestion? suggestion;
}

/// Разговор с коучем из истории — продолжается с того же места.
class CoachConversation {
  const CoachConversation({required this.id, required this.messages, this.quickReplies = const [], this.chat});

  factory CoachConversation.fromJson(Map<String, dynamic> json) {
    final chat = json['chat'] as Map<String, dynamic>?;
    return CoachConversation(
      id: json['id'] as String,
      messages: [
        for (final message in (json['messages'] as List<dynamic>).cast<Map<String, dynamic>>())
          CoachMessage.fromJson(message),
      ],
      quickReplies: [...?(json['quick_replies'] as List<dynamic>?)?.cast<String>()],
      chat: chat == null ? null : AttachedChat.fromJson(chat),
    );
  }

  final String id;

  /// Сообщения по порядку, первое — сверху.
  final List<CoachMessage> messages;

  /// Быстрые ответы из последнего ответа коуча.
  final List<String> quickReplies;

  /// Переписка, о которой разговор, — карточка «Chat attached».
  final AttachedChat? chat;
}
