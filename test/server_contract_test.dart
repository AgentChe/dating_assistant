import 'dart:io';

import 'package:dating_assistant/service/analysis/model/chat_breakdown.dart';
import 'package:dating_assistant/service/analysis/request/analyze_screenshot_request.dart';
import 'package:dating_assistant/service/coach/model/attached_chat.dart';
import 'package:dating_assistant/service/coach/model/coach_conversation.dart';
import 'package:dating_assistant/service/coach/model/coach_reply.dart';
import 'package:dating_assistant/service/coach/model/coach_tone.dart';
import 'package:dating_assistant/service/coach/request/send_coach_message_request.dart';
import 'package:dating_assistant/service/opening_line/model/opening_line.dart';
import 'package:dating_assistant/service/opening_line/request/generate_opening_line_request.dart';
import 'package:dating_assistant/service/profile/model/age_range.dart';
import 'package:dating_assistant/service/profile/model/dating_goal.dart';
import 'package:dating_assistant/service/profile/model/gender.dart';
import 'package:dating_assistant/service/profile/model/profile.dart';
import 'package:dating_assistant/service/profile/model/spice_level.dart';
import 'package:dating_assistant/service/profile/model/voice.dart';
import 'package:dating_assistant/transport/network_error.dart';
import 'package:dating_assistant/transport/rest_api_transport.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes/fake_analysis.dart';

/// Контракт с настоящим сервером: запрос собирают классы приложения, ответ читают его модели.
/// Сервер должен быть запущен (`go run .` в папке server), а тест — знать его адрес:
///
///     flutter test test/server_contract_test.dart --dart-define=CUE_SERVER_URL=http://localhost:8080
///
/// Без адреса тест пропускается: каждый запрос идёт в Gemini и стоит денег.
void main() {
  const serverUrl = String.fromEnvironment('CUE_SERVER_URL');
  const skip = serverUrl == '' ? 'pass --dart-define=CUE_SERVER_URL to check the real server' : null;
  const timeout = Timeout(Duration(seconds: 90));

  late RestApiTransport transport;

  setUpAll(() {
    // В debug RestApiTransport пишет в лог тела запросов, а в них скриншоты в base64.
    debugPrint = (message, {wrapWidth}) {};
    transport = RestApiTransport(baseUrl: serverUrl);
  });

  Uint8List screenshot(String name) => File('server/testdata/$name.jpg').readAsBytesSync();

  const you = Profile(
    goal: DatingGoal.relationship,
    gender: Gender.man,
    ageRange: AgeRange.from25To34,
    hardestParts: [],
    voice: Voice({VoiceTrait.lowercase}),
    spice: SpiceLevel.playful,
  );

  test('a chat screenshot comes back as its breakdown', () async {
    final json = await transport.callServerApi(AnalyzeScreenshotRequest(screenshot('chat')));
    final breakdown = ChatBreakdown.fromJson(json);

    expect(breakdown.id, startsWith('analysis-'));
    expect(breakdown.partner, (name: 'Nika', age: 28));
    expect(breakdown.theirWordShare + breakdown.yourWordShare, 100);
    expect(breakdown.theirInterest.level, inInclusiveRange(1, ChatBreakdown.interestSteps));
    expect(breakdown.goingWell, isNotEmpty);
    expect(breakdown.watchOut, isNotEmpty);
    expect(breakdown.topics.length, inInclusiveRange(2, 3));
    expect(breakdown.nextMove, isNotEmpty);
    // В историю разбор пишется тем же toJson — он должен прочитаться обратно.
    expect(ChatBreakdown.fromJson(breakdown.toJson()).toJson(), breakdown.toJson());
  }, skip: skip, timeout: timeout);

  test('what is not a chat is refused with 422', () async {
    await expectLater(
      transport.callServerApi(AnalyzeScreenshotRequest(screenshot('profile'))),
      throwsA(isA<NetworkError>().having((error) => error.statusCode, 'statusCode', 422)),
    );
  }, skip: skip, timeout: timeout);

  test('a profile screenshot comes back as a line and what the server read in it', () async {
    final first = OpeningLine.fromJson(
      await transport.callServerApi(
        GenerateOpeningLineRequest(spice: SpiceLevel.playful, you: you, profileScreenshot: screenshot('profile')),
      ),
    );
    expect(first.id, startsWith('line-'));
    expect(first.text, isNotEmpty);
    expect(first.match?.name, 'Sam');
    expect(first.match?.age, 27);

    // «Another one»: скриншот второй раз не шлём — шлём прочитанное и уже предложенную фразу.
    final next = OpeningLine.fromJson(
      await transport.callServerApi(
        GenerateOpeningLineRequest(spice: SpiceLevel.playful, you: you, match: first.match, previousLines: [first.text]),
      ),
    );
    expect(next.text, isNot(first.text));
    expect(next.match, isNull);
  }, skip: skip, timeout: timeout);

  test('the coach reads a breakdown, then makes the message bolder', () async {
    final breakdown = await exampleBreakdown();
    final first = CoachReply.fromJson(
      await transport.callServerApi(
        SendCoachMessageRequest(
          tone: CoachTone.auto,
          spice: SpiceLevel.warm,
          you: you,
          chat: AttachedChat.fromBreakdown(breakdown),
          breakdown: breakdown,
        ),
      ),
    );
    expect(first.id, startsWith('coach-'));
    expect(first.text, isNotEmpty);
    expect(first.suggestion?.text, isNotEmpty);
    expect(first.quickReplies, isNotEmpty);
    expect(first.chat, isNull);

    final conversation = CoachConversation.start(breakdown: breakdown).replied(reply: first, at: DateTime.now());
    final bolder = CoachReply.fromJson(
      await transport.callServerApi(
        SendCoachMessageRequest(
          text: 'Make it bolder',
          tone: CoachTone.auto,
          spice: SpiceLevel.warm,
          you: you,
          messages: conversation.messages,
          chat: conversation.chat,
          breakdown: breakdown,
        ),
      ),
    );
    expect(bolder.suggestion?.text, allOf(isNotEmpty, isNot(first.suggestion?.text)));
  }, skip: skip, timeout: timeout);

  test('a chat screenshot sent to the coach comes back as the attached chat card', () async {
    final reply = CoachReply.fromJson(
      await transport.callServerApi(
        SendCoachMessageRequest(tone: CoachTone.connect, spice: SpiceLevel.soft, chatScreenshot: screenshot('chat_quiet')),
      ),
    );
    expect(reply.text, isNotEmpty);
    expect(reply.chat?.name, 'Alex');
  }, skip: skip, timeout: timeout);

  test('an empty message to the coach is refused with 400', () async {
    await expectLater(
      transport.callServerApi(const SendCoachMessageRequest(text: ' ', tone: CoachTone.auto, spice: SpiceLevel.warm)),
      throwsA(isA<NetworkError>().having((error) => error.statusCode, 'statusCode', 400)),
    );
  }, skip: skip, timeout: timeout);
}
