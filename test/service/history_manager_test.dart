import 'package:dating_assistant/service/analysis/model/chat_breakdown.dart';
import 'package:dating_assistant/service/coach/model/coach_conversation.dart';
import 'package:dating_assistant/service/coach/model/coach_reply.dart';
import 'package:dating_assistant/service/history/history_manager.dart';
import 'package:dating_assistant/service/history/history_mediator.dart';
import 'package:dating_assistant/service/history/model/history_item.dart';
import 'package:dating_assistant/service/opening_line/model/opening_line.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive_ce.dart';

import '../fakes/fake_analysis.dart';
import '../fakes/fake_history.dart';

void main() {
  late ChatBreakdown breakdown;
  late Box<String> box;
  late HistoryMediator mediator;
  late HistoryManager history;
  late int changes;

  setUpAll(() async => breakdown = await exampleBreakdown());

  setUp(() async {
    box = await memoryHistoryBox();
    mediator = HistoryMediator();
    history = HistoryManager(box, mediator);
    changes = 0;
    mediator.changes.listen((_) => changes++);
  });

  final monday = DateTime.utc(2026, 11, 2, 10);

  CoachConversation conversation({DateTime? at, String suggestion = 'coffee thursday?'}) =>
      CoachConversation.start(at: monday).replied(
        text: 'Should I ask them out?',
        reply: CoachReply(
          id: 'coach-1',
          text: 'Good instinct.',
          suggestion: CoachSuggestion(text: suggestion),
        ),
        at: at ?? monday,
      );

  test('the history starts empty', () {
    expect(history.obtainHistory(), isEmpty);
  });

  test('a breakdown, a conversation and an opening line session are listed newest first', () async {
    await history.saveBreakdown(breakdown, at: monday);
    await history.saveConversation(conversation(at: monday.add(const Duration(hours: 1))));
    await history.saveOpeningLines(
      OpeningLineSession.start(
        const OpeningLine(id: 'line-1', text: 'perfect sunday, go'),
        match: const MatchDetails(name: 'Sam'),
        at: monday.add(const Duration(hours: 2)),
      ),
    );
    await pumpEventQueue();

    final [line, chat, analysis] = history.obtainHistory();
    expect(
      (line.kind, line.preview, line.partner),
      (HistoryKind.openingLine, 'perfect sunday, go', (name: 'Sam', age: null)),
    );
    expect((chat.kind, chat.preview, chat.partner), (HistoryKind.coachConversation, 'coffee thursday?', null));
    expect(
      (analysis.kind, analysis.id, analysis.preview),
      (HistoryKind.analysis, breakdown.id, 'Nika is into this — and doing most of the work.'),
    );
    expect(analysis.partner, (name: 'Nika', age: 28));
    expect(analysis.updatedAt, monday);
    // Вкладка History узнаёт о каждом сохранении.
    expect(changes, 3);
  });

  test('saving again updates the same record and moves it up', () async {
    final first = conversation(at: monday);
    await history.saveConversation(first);
    await history.saveBreakdown(breakdown, at: monday.add(const Duration(minutes: 1)));
    final next = first.replied(
      text: 'Make it bolder',
      reply: const CoachReply(
        id: 'coach-2',
        text: 'Bolder it is:',
        suggestion: CoachSuggestion(text: 'drinks?'),
      ),
      at: monday.add(const Duration(minutes: 2)),
    );
    await history.saveConversation(next);

    final items = history.obtainHistory();
    expect(items.map((item) => item.id), [first.id, breakdown.id]);
    expect(items.first.preview, 'drinks?');
  });

  test('every record opens in full', () async {
    final chat = conversation();
    final session =
        OpeningLineSession.start(
          const OpeningLine(id: 'line-1', text: 'first'),
          match: const MatchDetails(name: 'Sam', interests: 'Climbing'),
          at: monday,
        ).adding(
          const OpeningLine(id: 'line-2', text: 'second'),
          at: monday.add(const Duration(minutes: 1)),
        );
    await history.saveBreakdown(breakdown);
    await history.saveConversation(chat);
    await history.saveOpeningLines(session);

    expect(history.obtainBreakdown(breakdown.id)?.toJson(), breakdown.toJson());
    expect(history.obtainConversation(chat.id)?.toJson(), chat.toJson());
    final reopened = history.obtainOpeningLines(session.id);
    expect(reopened?.lines, ['first', 'second']);
    expect(reopened?.latest.text, 'second');
    expect(reopened?.match?.interests, 'Climbing');
    // Не тот тип записи или нет такой — null.
    expect(history.obtainConversation(breakdown.id), isNull);
    expect(history.obtainBreakdown('analysis-0'), isNull);
  });

  test('a record that cannot be read is skipped, not fatal', () async {
    await history.saveBreakdown(breakdown);
    await box.put('broken', '{"kind": "analysis", "updated_at": "not a date"}');
    await box.put('future', '{"kind": "imported_chat", "updated_at": "2026-11-08T10:00:00Z"}');

    expect(history.obtainHistory().single.id, breakdown.id);
    expect(history.obtainBreakdown('broken'), isNull);
  });

  test('a deleted record can be put back exactly as it was', () async {
    final chat = conversation();
    await history.saveConversation(chat);
    await history.saveBreakdown(breakdown, at: monday.add(const Duration(hours: 1)));
    // Уведомления о сохранении приходят асинхронно — дожидаемся их, чтобы считать только удаление и возврат.
    await pumpEventQueue();
    changes = 0;

    final deleted = await history.delete(chat.id);
    expect(history.obtainHistory().single.id, breakdown.id);
    expect(history.obtainConversation(chat.id), isNull);

    await history.restore(deleted!);
    await pumpEventQueue();

    // На своё место: по времени, а не наверх.
    expect(history.obtainHistory().map((item) => item.id), [breakdown.id, chat.id]);
    expect(history.obtainConversation(chat.id)?.toJson(), chat.toJson());
    expect(changes, 2);
    // Нечего удалять — нечего и возвращать.
    expect(await history.delete('conversation-0'), isNull);
  });

  test('a breakdown survives the round trip through JSON', () {
    expect(ChatBreakdown.fromJson(breakdown.toJson()).toJson(), breakdown.toJson());
  });
}
