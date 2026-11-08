import 'dart:typed_data';

import 'package:dating_assistant/service/analysis/analysis_manager.dart';
import 'package:dating_assistant/service/coach/coach_manager.dart';
import 'package:dating_assistant/service/coach/model/attached_chat.dart';
import 'package:dating_assistant/service/coach/model/coach_reply.dart';
import 'package:dating_assistant/service/coach/model/coach_tone.dart';
import 'package:dating_assistant/service/profile/profile_manager.dart';
import 'package:dating_assistant/service/usage/usage_mediator.dart';
import 'package:dating_assistant/transport/api_transport.dart';
import 'package:dating_assistant/transport/mock/mock_api_transport.dart';
import 'package:dating_assistant/transport/mock/mock_database.dart';
import 'package:dating_assistant/transport/mock/mock_server.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fake_profile.dart';

/// Коуч на моках без задержек, с профилем из онбординга. Разборы — на том же мок-сервере:
/// коуча можно открыть из разбора, а лимит считается один на всех.
typedef MockCoach = ({
  CoachManager manager,
  AnalysisManager analysisManager,
  ProfileManager profileManager,
  ApiTransport transport,
  MockDatabase database,
  UsageMediator usageMediator,
});

Future<MockCoach> mockCoach() async {
  final profileManager = await fakeProfileManager();
  final preferences = await SharedPreferencesWithCache.create(cacheOptions: const SharedPreferencesWithCacheOptions());
  final database = MockDatabase(preferences);
  final usageMediator = UsageMediator();
  final transport = MockApiTransport(
    server: MockServer(database, generationTime: Duration.zero),
    latency: Duration.zero,
  );
  return (
    manager: CoachManager(transport, profileManager, usageMediator),
    analysisManager: AnalysisManager(transport, usageMediator),
    profileManager: profileManager,
    transport: transport,
    database: database,
    usageMediator: usageMediator,
  );
}

/// Ответ коуча для тестов: совет и сообщение «Try sending».
CoachReply coachReply({String conversationId = 'conversation-1', String text = 'Keep it light:', AttachedChat? chat}) =>
    CoachReply(
      id: 'coach-$text',
      conversationId: conversationId,
      text: text,
      suggestion: const CoachSuggestion(text: 'coffee thursday?'),
      quickReplies: const ['Make it bolder'],
      chat: chat,
    );

/// Что ушло коучу.
typedef SentCoachMessage = ({
  String? conversationId,
  String? text,
  CoachTone tone,
  String? analysisId,
  Uint8List? chatScreenshot,
});

/// Коуч без сервера: по очереди отдаёт заданное в тесте и запоминает отправленное.
/// CoachReply или Future с ним — ответ, всё остальное бросается как ошибка.
class FakeCoachManager implements CoachManager {
  FakeCoachManager(this.results);

  final List<Object> results;

  final sent = <SentCoachMessage>[];

  @override
  Future<CoachReply> send({
    String? conversationId,
    String? text,
    required CoachTone tone,
    String? analysisId,
    Uint8List? chatScreenshot,
  }) async {
    sent.add((
      conversationId: conversationId,
      text: text,
      tone: tone,
      analysisId: analysisId,
      chatScreenshot: chatScreenshot,
    ));
    return switch (results.removeAt(0)) {
      final CoachReply reply => reply,
      final Future<CoachReply> reply => reply,
      final error => throw error,
    };
  }
}
