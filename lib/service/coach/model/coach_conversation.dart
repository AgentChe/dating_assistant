import 'package:dating_assistant/service/analysis/model/chat_breakdown.dart';
import 'package:dating_assistant/service/coach/model/attached_chat.dart';
import 'package:dating_assistant/service/coach/model/coach_reply.dart';

/// Сообщение в разговоре с коучем.
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

  /// null — пользователь только приложил скриншот переписки, без слов.
  final String? text;

  /// Что коуч предложил отправить.
  final CoachSuggestion? suggestion;

  Map<String, dynamic> toJson() => {
    'from': isFromCoach ? 'coach' : 'you',
    'text': ?text,
    'suggestion': ?suggestion?.toJson(),
  };
}

/// Разговор с коучем. Сервер его не помнит: разговор живёт в истории на устройстве,
/// и с каждым сообщением коучу уходит всё, что было до него.
class CoachConversation {
  const CoachConversation({
    required this.id,
    required this.updatedAt,
    this.messages = const [],
    this.quickReplies = const [],
    this.chat,
    this.breakdown,
  });

  /// Новый разговор; [breakdown] — разбор, из которого открыли коуча.
  factory CoachConversation.start({ChatBreakdown? breakdown, DateTime? at}) {
    final now = at ?? DateTime.now();
    return CoachConversation(
      id: 'conversation-${now.microsecondsSinceEpoch}',
      updatedAt: now,
      chat: breakdown == null ? null : AttachedChat.fromBreakdown(breakdown),
      breakdown: breakdown,
    );
  }

  factory CoachConversation.fromJson(Map<String, dynamic> json) {
    final chat = json['chat'] as Map<String, dynamic>?;
    final breakdown = json['breakdown'] as Map<String, dynamic>?;
    return CoachConversation(
      id: json['id'] as String,
      updatedAt: DateTime.parse(json['updated_at'] as String),
      messages: [
        for (final message in (json['messages'] as List<dynamic>).cast<Map<String, dynamic>>())
          CoachMessage.fromJson(message),
      ],
      quickReplies: [...?(json['quick_replies'] as List<dynamic>?)?.cast<String>()],
      chat: chat == null ? null : AttachedChat.fromJson(chat),
      breakdown: breakdown == null ? null : ChatBreakdown.fromJson(breakdown),
    );
  }

  final String id;

  /// Когда коуч ответил последний раз.
  final DateTime updatedAt;

  /// Сообщения по порядку, первое — сверху.
  final List<CoachMessage> messages;

  /// Быстрые ответы из последнего ответа коуча.
  final List<String> quickReplies;

  /// Переписка, о которой разговор, — карточка «Chat attached».
  final AttachedChat? chat;

  /// Разбор переписки, если коуча открыли из него: коуч получает его с каждым сообщением.
  final ChatBreakdown? breakdown;

  /// Ещё ничего не спросили.
  bool get isEmpty => messages.isEmpty;

  /// Последнее, что коуч предложил отправить, или его последний ответ — превью в истории.
  String? get preview {
    final reply = messages.lastWhere(
      (message) => message.isFromCoach,
      orElse: () => const CoachMessage(isFromCoach: true),
    );
    return reply.suggestion?.text ?? reply.text;
  }

  /// Разговор с новым вопросом и ответом на него. Без [text] пользователь приложил скриншот.
  CoachConversation replied({String? text, required CoachReply reply, required DateTime at}) => CoachConversation(
    id: id,
    updatedAt: at,
    messages: [
      ...messages,
      CoachMessage(isFromCoach: false, text: text),
      CoachMessage(isFromCoach: true, text: reply.text, suggestion: reply.suggestion),
    ],
    quickReplies: reply.quickReplies,
    chat: reply.chat ?? chat,
    breakdown: breakdown,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'updated_at': updatedAt.toUtc().toIso8601String(),
    'messages': [for (final message in messages) message.toJson()],
    'quick_replies': quickReplies,
    'chat': ?chat?.toJson(),
    'breakdown': ?breakdown?.toJson(),
  };
}
