import 'package:dating_assistant/service/analysis/model/chat_breakdown.dart';

/// Что лежит в истории.
enum HistoryKind {
  /// Разбор переписки — открывается «Chat breakdown».
  analysis,

  /// Разговор с коучем — открывается Dating advice с того же места.
  coachConversation,

  /// Фразы для одного мэтча — открывается последняя фраза.
  openingLine,
}

/// Запись истории для строки списка; саму запись HistoryManager отдаёт по [id].
class HistoryItem {
  const HistoryItem({
    required this.kind,
    required this.id,
    required this.updatedAt,
    required this.preview,
    this.partner,
  });

  final HistoryKind kind;

  final String id;

  /// Когда запись менялась последний раз: новый ответ коуча или новая фраза поднимают её наверх.
  final DateTime updatedAt;

  /// Вывод разбора, последнее сообщение, которое предложил коуч, или последняя фраза.
  final String preview;

  /// С кем переписка или для кого фраза — если известно.
  final ChatPartner? partner;
}
