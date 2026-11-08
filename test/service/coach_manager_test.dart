import 'package:dating_assistant/service/coach/model/attached_chat.dart';
import 'package:dating_assistant/service/coach/model/coach_reply.dart';
import 'package:dating_assistant/service/coach/model/coach_tone.dart';
import 'package:dating_assistant/service/coach/request/send_coach_message_request.dart';
import 'package:dating_assistant/service/profile/model/spice_level.dart';
import 'package:dating_assistant/service/usage/usage_manager.dart';
import 'package:dating_assistant/transport/network_error.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_analysis.dart';
import '../fakes/fake_coach.dart';
import '../fakes/fake_profile.dart';

void main() {
  late MockCoach mock;
  late int generationsUsed;

  setUp(() async {
    mock = await mockCoach();
    generationsUsed = 0;
    mock.usageMediator.changes.listen((_) => generationsUsed++);
  });

  Future<Object?> errorOf(Future<CoachReply> request) =>
      request.then<Object?>((_) => null, onError: (Object error) => error);

  test('a question starts a conversation and gets advice with a message to send', () async {
    final reply = await mock.manager.send(text: 'Should I ask them out?', tone: CoachTone.auto);
    await pumpEventQueue();

    expect(reply.conversationId, isNotEmpty);
    expect(reply.text, startsWith('Good instinct — chats burn out when they drag.'));
    expect(reply.suggestion?.text, 'coffee thursday or a walk this weekend — which sounds more like you?');
    expect(reply.quickReplies, ['Make it bolder', 'Give me another option']);
    expect(reply.chat, isNull);
    expect(generationsUsed, 1);
  });

  test('follow-ups stay on the topic and never repeat a message', () async {
    final first = await mock.manager.send(text: 'Should I ask them out?', tone: CoachTone.auto);
    final another = await mock.manager.send(
      conversationId: first.conversationId,
      text: 'Give me another option',
      tone: CoachTone.auto,
    );
    final bolder = await mock.manager.send(
      conversationId: first.conversationId,
      text: 'Make it bolder',
      tone: CoachTone.flirt,
    );

    expect(another.conversationId, first.conversationId);
    expect(another.suggestion?.text, isNot(first.suggestion?.text));
    expect(bolder.text, startsWith('Bolder it is'));
    expect(bolder.suggestion?.text, isNot(anyOf(first.suggestion?.text, another.suggestion?.text)));
  });

  test('a new topic in the same conversation gets its own advice', () async {
    final first = await mock.manager.send(text: 'Should I ask them out?', tone: CoachTone.auto);
    final next = await mock.manager.send(
      conversationId: first.conversationId,
      text: 'They stopped replying',
      tone: CoachTone.auto,
    );

    expect(next.text, startsWith('It happens, and it’s usually timing'));
    expect(next.suggestion?.why, isNotNull);
    expect(next.quickReplies, contains('What if there’s no reply?'));
  });

  test('a chat screenshot is read: the reply says who the chat is with', () async {
    final reply = await mock.manager.send(tone: CoachTone.auto, chatScreenshot: fakeScreenshot);

    expect(reply.chat?.name, 'Nika');
    expect(reply.chat?.age, 28);
    expect(reply.chat?.verdict, 'Nika is into this — and doing most of the work.');
    expect(reply.text, startsWith('I read your chat. Nika is putting in most of the effort'));
    expect(
      reply.suggestion?.text,
      'sounds like the good kind of escape. which mountains — and what would get you back down?',
    );
    expect(reply.suggestion?.why, 'It answers the last message and hands the next question back.');
  });

  test('the coach opened from a breakdown talks about that chat', () async {
    final breakdown = await mock.analysisManager.analyzeScreenshot(fakeScreenshot);

    final reply = await mock.manager.send(tone: CoachTone.auto, analysisId: breakdown.id);

    expect(reply.text, startsWith('I read your chat. Nika'));
    // Карточку переписки клиент строит из разбора сам.
    expect(reply.chat, isNull);
    final chat = AttachedChat.fromBreakdown(breakdown);
    expect((chat.name, chat.age, chat.verdict), ('Nika', 28, 'Nika is into this — and doing most of the work.'));
  });

  test('an unknown conversation or breakdown is an error and costs no generation', () async {
    final unknownConversation = await errorOf(
      mock.manager.send(conversationId: 'conversation-0', text: 'Hi', tone: CoachTone.auto),
    );
    final unknownAnalysis = await errorOf(mock.manager.send(analysisId: 'analysis-0', tone: CoachTone.auto));

    expect((unknownConversation! as NetworkError).statusCode, 404);
    expect((unknownAnalysis! as NetworkError).statusCode, 404);
    expect((await UsageManager(mock.transport).obtainUsage()).used, 0);
  });

  test('the request carries the tone, the default spice and the voice', () {
    final request = SendCoachMessageRequest(
      text: 'Hi',
      tone: CoachTone.intrigue,
      spice: SpiceLevel.bold,
      you: fakeProfile,
      analysisId: 'analysis-1',
    );

    expect(request.path, '/api/v1/coach/messages');
    expect(request.body, {
      'text': 'Hi',
      'tone': 'intrigue',
      'spice': 'bold',
      'you': {
        'gender': 'woman',
        'age_range': 'from25To34',
        'goal': 'relationship',
        'voice': ['lowercase', 'direct'],
      },
      'analysis_id': 'analysis-1',
    });
  });

  test('after three free generations the server asks for Cue Plus', () async {
    var conversationId = (await mock.manager.send(text: 'Help me start a chat', tone: CoachTone.auto)).conversationId;
    for (final text in ['Give me another option', 'Make it bolder']) {
      conversationId = (await mock.manager.send(
        conversationId: conversationId,
        text: text,
        tone: CoachTone.auto,
      )).conversationId;
    }

    final error = await errorOf(
      mock.manager.send(conversationId: conversationId, text: 'One more', tone: CoachTone.auto),
    );
    await pumpEventQueue();

    expect(UsageManager.isGenerationLimit(error!), isTrue);
    expect(generationsUsed, 3);
  });
}
