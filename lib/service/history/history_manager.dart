import 'dart:convert';

import 'package:dating_assistant/service/analysis/model/chat_breakdown.dart';
import 'package:dating_assistant/service/coach/model/attached_chat.dart';
import 'package:dating_assistant/service/coach/model/coach_conversation.dart';
import 'package:dating_assistant/service/history/history_mediator.dart';
import 'package:dating_assistant/service/history/model/history_item.dart';
import 'package:dating_assistant/service/opening_line/model/opening_line.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_ce/hive_ce.dart';

/// История (аналог XxxManager из Swift-проектов): разборы, разговоры с коучем и фразы для мэтчей.
/// Хранится только на устройстве — в Hive, по записи на разбор, разговор или сессию фраз.
///
/// Запись — JSON-строка `{"kind", "updated_at", ...}` под своим id: так в ящике не нужны адаптеры типов,
/// а модели читаются и пишутся тем же toJson/fromJson, что и ответы сервера.
class HistoryManager {
  HistoryManager(this._box, this._mediator);

  final Box<String> _box;

  final HistoryMediator _mediator;

  /// Новые сверху. Запись, которую не прочитать (от старой версии моделей), пропускаем.
  List<HistoryItem> obtainHistory() => [
    for (final MapEntry(:key, :value) in _box.toMap().entries) ?_item(key as String, value),
  ]..sort((first, second) => second.updatedAt.compareTo(first.updatedAt));

  ChatBreakdown? obtainBreakdown(String id) =>
      _read(id, _analysis, (record) => ChatBreakdown.fromJson(record['breakdown'] as Map<String, dynamic>));

  CoachConversation? obtainConversation(String id) => _read(
    id,
    _conversation,
    (record) => CoachConversation.fromJson(record['conversation'] as Map<String, dynamic>),
  );

  OpeningLineSession? obtainOpeningLines(String id) => _read(
    id,
    _openingLines,
    (record) => OpeningLineSession.fromJson(record['session'] as Map<String, dynamic>),
  );

  /// Разбор, который пользователь досмотрел до конца сканирования.
  Future<void> saveBreakdown(ChatBreakdown breakdown, {DateTime? at}) =>
      _write(breakdown.id, _analysis, at ?? DateTime.now(), {'breakdown': breakdown.toJson()});

  /// Разговор после очередного ответа коуча.
  Future<void> saveConversation(CoachConversation conversation) =>
      _write(conversation.id, _conversation, conversation.updatedAt, {'conversation': conversation.toJson()});

  /// Сессия фраз после очередной фразы.
  Future<void> saveOpeningLines(OpeningLineSession session) =>
      _write(session.id, _openingLines, session.updatedAt, {'session': session.toJson()});

  /// Удаляет запись. Вернуть её можно, пока жив ответ, — для «Undo»; null — такой записи уже нет.
  Future<DeletedHistoryRecord?> delete(String id) async {
    final raw = _box.get(id);
    if (raw == null) return null;
    await _box.delete(id);
    _mediator.notifyChanged();
    return DeletedHistoryRecord._(id, raw);
  }

  /// «Undo»: запись возвращается такой, какой была, на своё место в списке.
  Future<void> restore(DeletedHistoryRecord record) async {
    await _box.put(record.id, record._raw);
    _mediator.notifyChanged();
  }

  /// «Delete my data»: вся история, без возврата.
  Future<void> deleteAll() async {
    await _box.clear();
    _mediator.notifyChanged();
  }

  static const _analysis = 'analysis';

  static const _conversation = 'coach_conversation';

  static const _openingLines = 'opening_line';

  Future<void> _write(String id, String kind, DateTime updatedAt, Map<String, dynamic> payload) async {
    await _box.put(id, jsonEncode({'kind': kind, 'updated_at': updatedAt.toUtc().toIso8601String(), ...payload}));
    _mediator.notifyChanged();
  }

  T? _read<T>(String id, String kind, T Function(Map<String, dynamic> record) parse) {
    final raw = _box.get(id);
    if (raw == null) return null;
    try {
      final record = jsonDecode(raw) as Map<String, dynamic>;
      return record['kind'] == kind ? parse(record) : null;
    } catch (error) {
      debugPrint('HistoryManager: cannot read $id: $error');
      return null;
    }
  }

  /// Строка списка: что за запись, превью и с кем.
  HistoryItem? _item(String id, String raw) {
    try {
      final record = jsonDecode(raw) as Map<String, dynamic>;
      final updatedAt = DateTime.parse(record['updated_at'] as String);
      switch (record['kind']) {
        case _analysis:
          final breakdown = ChatBreakdown.fromJson(record['breakdown'] as Map<String, dynamic>);
          return HistoryItem(
            kind: HistoryKind.analysis,
            id: id,
            updatedAt: updatedAt,
            preview: AttachedChat.fromBreakdown(breakdown).verdict ?? '',
            partner: breakdown.partner,
          );
        case _conversation:
          final conversation = CoachConversation.fromJson(record['conversation'] as Map<String, dynamic>);
          final chat = conversation.chat;
          return HistoryItem(
            kind: HistoryKind.coachConversation,
            id: id,
            updatedAt: updatedAt,
            preview: conversation.preview ?? '',
            partner: chat == null ? null : (name: chat.name, age: chat.age),
          );
        case _openingLines:
          final session = OpeningLineSession.fromJson(record['session'] as Map<String, dynamic>);
          final name = session.match?.name;
          return HistoryItem(
            kind: HistoryKind.openingLine,
            id: id,
            updatedAt: updatedAt,
            preview: session.lines.last,
            partner: name == null || name.isEmpty ? null : (name: name, age: session.match?.age),
          );
      }
    } catch (error) {
      debugPrint('HistoryManager: cannot read $id: $error');
    }
    return null;
  }
}

/// Удалённая запись истории. Внутри — то, что лежало в хранилище, поэтому вернуть её может только HistoryManager.
class DeletedHistoryRecord {
  const DeletedHistoryRecord._(this.id, this._raw);

  final String id;

  final String _raw;
}
