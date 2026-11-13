import 'dart:typed_data';

import 'package:dating_assistant/service/analysis/analysis_manager.dart';
import 'package:dating_assistant/service/coach/coach_manager.dart';
import 'package:dating_assistant/service/coach/model/attached_chat.dart';
import 'package:dating_assistant/service/coach/model/coach_conversation.dart';
import 'package:dating_assistant/service/coach/model/coach_reply.dart';
import 'package:dating_assistant/service/coach/model/coach_tone.dart';
import 'package:dating_assistant/service/profile/profile_manager.dart';
import 'package:dating_assistant/service/usage/usage_manager.dart';
import 'package:dating_assistant/service/usage/usage_mediator.dart';
import 'package:dating_assistant/transport/api_transport.dart';
import 'package:dating_assistant/transport/mock/mock_api_transport.dart';
import 'package:dating_assistant/transport/mock/mock_server.dart';

import 'fake_profile.dart';
import 'fake_usage.dart';

/// Коуч на моках без задержек, с профилем из онбординга. Разборы — на том же мок-сервере:
/// коуча можно открыть из разбора, а счётчик генераций у них общий.
typedef MockCoach = ({
  CoachManager manager,
  AnalysisManager analysisManager,
  ProfileManager profileManager,
  ApiTransport transport,
  UsageManager usageManager,
  UsageMediator usageMediator,
});

Future<MockCoach> mockCoach() async {
  final profileManager = await fakeProfileManager();
  final usageMediator = UsageMediator();
  final usageManager = memoryUsageManager(usageMediator: usageMediator);
  final transport = MockApiTransport(server: MockServer(generationTime: Duration.zero), latency: Duration.zero);
  return (
    manager: CoachManager(transport, profileManager, usageManager),
    analysisManager: AnalysisManager(transport, usageManager),
    profileManager: profileManager,
    transport: transport,
    usageManager: usageManager,
    usageMediator: usageMediator,
  );
}

/// Ответ коуча для тестов: совет и сообщение «Try sending».
CoachReply coachReply({String text = 'Keep it light:', AttachedChat? chat}) => CoachReply(
  id: 'coach-$text',
  text: text,
  suggestion: const CoachSuggestion(text: 'coffee thursday?'),
  quickReplies: const ['Make it bolder'],
  chat: chat,
);

/// Что ушло коучу: разговор до сообщения и само сообщение.
typedef SentCoachMessage = ({CoachConversation conversation, String? text, CoachTone tone, Uint8List? chatScreenshot});

/// Коуч без сервера: по очереди отдаёт заданное в тесте и запоминает отправленное.
/// CoachReply или Future с ним — ответ, всё остальное бросается как ошибка.
class FakeCoachManager implements CoachManager {
  FakeCoachManager(this.results);

  final List<Object> results;

  final sent = <SentCoachMessage>[];

  @override
  Future<CoachReply> send({
    required CoachConversation conversation,
    String? text,
    required CoachTone tone,
    Uint8List? chatScreenshot,
  }) async {
    sent.add((conversation: conversation, text: text, tone: tone, chatScreenshot: chatScreenshot));
    return switch (results.removeAt(0)) {
      final CoachReply reply => reply,
      final Future<CoachReply> reply => reply,
      final error => throw error,
    };
  }
}
