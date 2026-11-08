import 'package:dating_assistant/service/coach/model/coach_tone.dart';
import 'package:dating_assistant/service/history/model/history_item.dart';
import 'package:dating_assistant/service/opening_line/model/opening_line.dart';
import 'package:dating_assistant/service/profile/model/spice_level.dart';
import 'package:dating_assistant/transport/network_error.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_analysis.dart';
import '../fakes/fake_history.dart';

void main() {
  late MockBackend mock;

  setUp(() async => mock = await mockBackend());

  Future<Object?> errorOf(Future<Object> request) =>
      request.then<Object?>((_) => null, onError: (Object error) => error);

  test('the history starts empty', () async {
    expect(await mock.history.obtainHistory(), isEmpty);
  });

  test('a breakdown, a coach conversation and an opening line session land in the history, newest first', () async {
    final breakdown = await mock.analysis.analyzeScreenshot(fakeScreenshot);
    final reply = await mock.coach.send(text: 'Should I ask them out?', tone: CoachTone.auto);
    final line = await mock.openingLines.generate(
      spice: SpiceLevel.warm,
      match: const MatchDetails(name: 'Sam'),
    );

    final history = await mock.history.obtainHistory();

    expect(history.map((item) => (item.kind, item.id)), [
      (HistoryKind.openingLine, line.sessionId),
      (HistoryKind.coachConversation, reply.conversationId),
      (HistoryKind.analysis, breakdown.id),
    ]);
    final [openingLine, conversation, analysis] = history;
    expect(openingLine.preview, line.text);
    expect(openingLine.partner?.name, 'Sam');
    expect(conversation.preview, 'coffee thursday or a walk this weekend — which sounds more like you?');
    expect(conversation.partner, isNull);
    expect(analysis.preview, 'Nika is into this — and doing most of the work.');
    expect(analysis.partner, (name: 'Nika', age: 28));
    expect(analysis.updatedAt.isBefore(conversation.updatedAt), isTrue);
  });

  test('Another one stays in the same session: one record with the latest line', () async {
    final first = await mock.openingLines.generate(spice: SpiceLevel.warm);
    final second = await mock.openingLines.generate(spice: SpiceLevel.warm, sessionId: first.sessionId);

    final history = await mock.history.obtainHistory();

    expect(second.sessionId, first.sessionId);
    expect(history.single.preview, second.text);
    expect(history.single.partner, isNull);
  });

  test('a new answer from the coach moves the conversation to the top', () async {
    final reply = await mock.coach.send(text: 'Should I ask them out?', tone: CoachTone.auto);
    await mock.analysis.analyzeScreenshot(fakeScreenshot);
    await mock.coach.send(conversationId: reply.conversationId, text: 'Make it bolder', tone: CoachTone.auto);

    final history = await mock.history.obtainHistory();

    expect(history.first.id, reply.conversationId);
    expect(history.first.preview, 'let’s take this offline. coffee thursday — i’ll pick the place');
  });

  test('a saved breakdown opens in full', () async {
    final breakdown = await mock.analysis.analyzeScreenshot(fakeScreenshot);

    final saved = await mock.analysis.obtainAnalysis(breakdown.id);

    expect(saved.id, breakdown.id);
    expect(saved.partner, (name: 'Nika', age: 28));
    expect(saved.nextMove, breakdown.nextMove);
    expect(((await errorOf(mock.analysis.obtainAnalysis('analysis-0')))! as NetworkError).statusCode, 404);
  });

  test('a coach conversation comes back message by message, with its chat and quick replies', () async {
    final first = await mock.coach.send(tone: CoachTone.auto, chatScreenshot: fakeScreenshot);
    await mock.coach.send(conversationId: first.conversationId, text: 'Give me another option', tone: CoachTone.auto);

    final conversation = await mock.coach.obtainConversation(first.conversationId);

    expect(conversation.id, first.conversationId);
    expect(conversation.chat?.name, 'Nika');
    expect(conversation.messages.map((message) => (message.isFromCoach, message.text?.split(' ').first)), [
      // Скриншот без слов — сообщение пользователя без текста.
      (false, null),
      (true, 'I'),
      (false, 'Give'),
      (true, 'Here’s'),
    ]);
    expect(conversation.messages[1].suggestion?.why, 'It answers the last message and hands the next question back.');
    expect(conversation.quickReplies, ['Give me another option', 'Make it bolder', 'What if there’s no reply?']);

    final history = await mock.history.obtainHistory();
    expect(history.single.partner, (name: 'Nika', age: 28));
  });

  test('an opening line session reopens with its latest line and what is known about the match', () async {
    final first = await mock.openingLines.generate(
      spice: SpiceLevel.playful,
      match: const MatchDetails(name: 'Sam', interests: 'Climbing, bad puns'),
    );
    final latest = await mock.openingLines.generate(spice: SpiceLevel.playful, sessionId: first.sessionId);

    final reopened = await mock.openingLines.obtainSession(first.sessionId);

    expect(reopened.text, latest.text);
    expect(reopened.sessionId, first.sessionId);
    expect(reopened.match?.name, 'Sam');
    expect(reopened.match?.interests, 'Climbing, bad puns');
    // Дальше сессия не повторяет уже предложенные фразы, даже без списка от клиента.
    final next = await mock.openingLines.generate(spice: SpiceLevel.playful, sessionId: first.sessionId);
    expect(next.text, isNot(anyOf(first.text, latest.text)));
  });

  test('records of a type this version does not know are skipped', () {
    expect(
      HistoryItem.fromJson({'type': 'imported_chat', 'id': 'import-1', 'updated_at': '2026-11-08T10:00:00Z'}),
      isNull,
    );
    final item = HistoryItem.fromJson({
      'type': 'coach_conversation',
      'id': 'conversation-1',
      'updated_at': '2026-11-08T10:00:00Z',
      'preview': 'coffee thursday?',
    });
    expect(item?.kind, HistoryKind.coachConversation);
    expect(item?.updatedAt, DateTime.utc(2026, 11, 8, 10));
  });
}
