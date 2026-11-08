import 'package:dating_assistant/service/analysis/model/chat_breakdown.dart';

/// Что лежит в истории.
enum HistoryKind {
  /// Разбор переписки — открывается «Chat breakdown».
  analysis,

  /// Разговор с коучем — открывается Dating advice с того же места.
  coachConversation,

  /// Сессия первых фраз для одного мэтча — открывается последняя фраза.
  openingLine,
}

/// Запись в истории — то, что нужно для строки списка. Саму запись загружает её домен по [id].
class HistoryItem {
  const HistoryItem({
    required this.kind,
    required this.id,
    required this.updatedAt,
    required this.preview,
    this.partner,
  });

  /// null — запись типа, которого эта версия приложения не знает: её не показываем.
  static HistoryItem? fromJson(Map<String, dynamic> json) {
    final kind = switch (json['type']) {
      'analysis' => HistoryKind.analysis,
      'coach_conversation' => HistoryKind.coachConversation,
      'opening_line' => HistoryKind.openingLine,
      _ => null,
    };
    if (kind == null) return null;
    final partner = json['partner'] as Map<String, dynamic>?;
    return HistoryItem(
      kind: kind,
      id: json['id'] as String,
      updatedAt: DateTime.parse(json['updated_at'] as String),
      preview: json['preview'] as String? ?? '',
      partner: partner == null ? null : (name: partner['name'] as String, age: partner['age'] as int?),
    );
  }

  final HistoryKind kind;

  final String id;

  /// Когда запись менялась последний раз: новый ответ коуча или новая фраза поднимают её наверх.
  final DateTime updatedAt;

  /// Вывод разбора, последнее сообщение, которое предложил коуч, или последняя фраза.
  final String preview;

  /// С кем переписка или для кого фраза — если известно.
  final ChatPartner? partner;
}
