import 'package:dating_assistant/service/coach/model/attached_chat.dart';

/// Готовое сообщение, которое коуч предлагает отправить («Try sending»).
class CoachSuggestion {
  const CoachSuggestion({required this.text, this.why});

  factory CoachSuggestion.fromJson(Map<String, dynamic> json) =>
      CoachSuggestion(text: json['text'] as String, why: json['why'] as String?);

  final String text;

  /// Почему это сработает: «It answers the last message and hands the next question back.».
  final String? why;
}

/// Ответ коуча: совет и, если нужно, готовое сообщение.
class CoachReply {
  const CoachReply({
    required this.id,
    required this.conversationId,
    required this.text,
    this.suggestion,
    this.quickReplies = const [],
    this.chat,
  });

  factory CoachReply.fromJson(Map<String, dynamic> json) {
    final suggestion = json['suggestion'] as Map<String, dynamic>?;
    final chat = json['chat'] as Map<String, dynamic>?;
    return CoachReply(
      id: json['id'] as String,
      conversationId: json['conversation_id'] as String,
      text: json['text'] as String,
      suggestion: suggestion == null ? null : CoachSuggestion.fromJson(suggestion),
      quickReplies: [...?(json['quick_replies'] as List<dynamic>?)?.cast<String>()],
      chat: chat == null ? null : AttachedChat.fromJson(chat),
    );
  }

  final String id;

  /// Разговор, в котором коуч ответил. Следующие сообщения отправляем в него: предыдущие сервер помнит сам.
  final String conversationId;

  final String text;

  final CoachSuggestion? suggestion;

  /// Что можно спросить дальше одним нажатием: «Make it bolder», «Give me another option».
  final List<String> quickReplies;

  /// Что сервер прочитал в переписке со скриншота — для карточки «Chat attached».
  final AttachedChat? chat;
}
