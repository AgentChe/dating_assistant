import 'package:dating_assistant/service/coach/model/attached_chat.dart';
import 'package:dating_assistant/service/coach/model/coach_conversation.dart';
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

  /// Спрашивает коуча и дописывает ответ в разговор — как это делает экран.
  Future<CoachConversation> ask(CoachConversation conversation, String text) async {
    final reply = await mock.manager.send(conversation: conversation, text: text, tone: CoachTone.auto);
    return conversation.replied(text: text, reply: reply, at: DateTime.now());
  }

  test('a question gets advice with a message to send', () async {
    final reply = await mock.manager.send(
      conversation: CoachConversation.start(),
      text: 'Should I ask them out?',
      tone: CoachTone.auto,
    );
    await pumpEventQueue();

    expect(reply.text, startsWith('Good instinct — chats burn out when they drag.'));
    expect(reply.suggestion?.text, 'coffee thursday or a walk this weekend — which sounds more like you?');
    expect(reply.quickReplies, ['Make it bolder', 'Give me another option']);
    expect(reply.chat, isNull);
    expect(generationsUsed, 1);
  });

  test('the server remembers nothing: follow-ups work from the messages sent along', () async {
    var conversation = await ask(CoachConversation.start(), 'Should I ask them out?');
    conversation = await ask(conversation, 'Give me another option');
    conversation = await ask(conversation, 'Make it bolder');

    final [first, another, bolder] = [
      for (final message in conversation.messages)
        if (message.isFromCoach) message,
    ];
    expect(another.text, 'Here’s another way to play it:');
    expect(another.suggestion?.text, isNot(first.suggestion?.text));
    expect(bolder.text, startsWith('Bolder it is'));
    expect(bolder.suggestion?.text, isNot(anyOf(first.suggestion?.text, another.suggestion?.text)));
  });

  test('a new topic in the same conversation gets its own advice', () async {
    var conversation = await ask(CoachConversation.start(), 'Should I ask them out?');
    conversation = await ask(conversation, 'They stopped replying');

    final reply = conversation.messages.last;
    expect(reply.text, startsWith('It happens, and it’s usually timing'));
    expect(reply.suggestion?.why, isNotNull);
    expect(conversation.quickReplies, contains('What if there’s no reply?'));
  });

  test('a chat screenshot is read: the reply says who the chat is with', () async {
    final reply = await mock.manager.send(
      conversation: CoachConversation.start(),
      tone: CoachTone.auto,
      chatScreenshot: fakeScreenshot,
    );

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

  test('opened from a breakdown, the coach talks about that chat first and then goes on', () async {
    final breakdown = await mock.analysisManager.analyzeScreenshot(fakeScreenshot);
    final start = CoachConversation.start(breakdown: breakdown);

    final first = await mock.manager.send(conversation: start, tone: CoachTone.auto);
    final conversation = start.replied(reply: first, at: DateTime.now());
    final next = await ask(conversation, 'Should I ask them out?');

    expect(first.text, startsWith('I read your chat. Nika'));
    // Карточку переписки клиент строит из разбора сам.
    expect(first.chat, isNull);
    expect(next.messages.last.text, startsWith('Good instinct'));
    expect(next.chat?.name, 'Nika');
  });

  test('the request carries the conversation so far, the chat, the tone, the spice and the voice', () async {
    final breakdown = await mock.analysisManager.analyzeScreenshot(fakeScreenshot);
    final conversation = CoachConversation.start(breakdown: breakdown).replied(
      reply: const CoachReply(
        id: 'coach-1',
        text: 'I read your chat.',
        suggestion: CoachSuggestion(text: 'hi!'),
      ),
      at: DateTime.utc(2026, 11, 8),
    );

    final body = SendCoachMessageRequest(
      text: 'Make it bolder',
      tone: CoachTone.intrigue,
      spice: SpiceLevel.bold,
      you: fakeProfile,
      messages: conversation.messages,
      chat: conversation.chat,
      breakdown: conversation.breakdown,
    ).body;

    expect(body['text'], 'Make it bolder');
    expect(body['tone'], 'intrigue');
    expect(body['spice'], 'bold');
    expect(body['you'], {
      'gender': 'woman',
      'age_range': 'from25To34',
      'goal': 'relationship',
      'voice': ['lowercase', 'direct'],
    });
    expect(body['messages'], [
      {'from': 'you'},
      {
        'from': 'coach',
        'text': 'I read your chat.',
        'suggestion': {'text': 'hi!'},
      },
    ]);
    expect(body['chat'], {'name': 'Nika', 'age': 28, 'verdict': 'Nika is into this — and doing most of the work.'});
    expect((body['breakdown'] as Map<String, dynamic>)['next_move'], breakdown.nextMove);
    expect(body.containsKey('chat_screenshot'), isFalse);
  });

  test('a message with nothing in it is refused and costs no generation', () async {
    final error = await errorOf(mock.manager.send(conversation: CoachConversation.start(), tone: CoachTone.auto));

    expect((error! as NetworkError).statusCode, 400);
    expect((await mock.usageManager.obtainUsage()).used, 0);
  });

  test('the fourth free generation in a week asks for Cue Plus', () async {
    var conversation = CoachConversation.start();
    for (final text in ['Help me start a chat', 'Give me another option', 'Make it bolder']) {
      conversation = await ask(conversation, text);
    }

    final error = await errorOf(
      mock.manager.send(conversation: conversation, text: 'One more', tone: CoachTone.auto),
    );
    await pumpEventQueue();

    expect(UsageManager.isGenerationLimit(error!), isTrue);
    expect(generationsUsed, 3);
  });

  test('a conversation comes back from JSON exactly as it was', () async {
    final breakdown = await mock.analysisManager.analyzeScreenshot(fakeScreenshot);
    final conversation = CoachConversation.start(breakdown: breakdown).replied(
      text: 'Make it bolder',
      reply: const CoachReply(
        id: 'coach-1',
        text: 'Bolder it is:',
        suggestion: CoachSuggestion(text: 'coffee thursday?', why: 'Easy to answer.'),
        quickReplies: ['Give me another option'],
        chat: AttachedChat(name: 'Nika', age: 28, verdict: 'Nika is into this.'),
      ),
      at: DateTime.utc(2026, 11, 8, 10),
    );

    final restored = CoachConversation.fromJson(conversation.toJson());

    expect(restored.toJson(), conversation.toJson());
    expect(restored.updatedAt, DateTime.utc(2026, 11, 8, 10));
    expect(restored.messages.last.suggestion?.why, 'Easy to answer.');
    expect(restored.chat?.verdict, 'Nika is into this.');
    expect(restored.breakdown?.toJson(), breakdown.toJson());
  });
}
