import 'package:dating_assistant/transport/mock/mock_request.dart';
import 'package:dating_assistant/transport/network_error.dart';

/// Заготовки коуча на одну тему: совет, варианты сообщения, смелый вариант и что спросить дальше.
typedef _Topic = ({String advice, List<String> lines, String bolder, String? why, List<String> quickReplies});

/// Ответ мока: тема разговора, совет и сообщение «Try sending».
typedef _Reply = ({String topic, String advice, String line, String? why, List<String> quickReplies});

/// Коуч (Dating advice). Мок не читает скриншот и не учитывает тон: на переписку отвечает примером из Figma
/// про Nika, на текст — заготовкой по теме, которую узнаёт по словам («ask them out», «stopped replying»).
///
/// Сервер разговоров не хранит, всё нужное приходит в запросе: «Give me another option» и «Make it bolder»
/// относятся к теме последнего ответа коуча из `messages`, а уже предложенные там сообщения не повторяются.
class CoachMockRoutes {
  CoachMockRoutes({required this.generationTime});

  /// Сколько «думает» нейросеть — чтобы на моках было видно, как коуч печатает.
  final Duration generationTime;

  Map<String, MockHandler> get routes => {'POST /api/v1/coach/messages': _send};

  Future<Map<String, dynamic>> _send(MockRequest request) async {
    final body = request.body;
    final text = (body['text'] as String? ?? '').trim();
    final hasScreenshot = (body['chat_screenshot'] as String? ?? '').isNotEmpty;
    final messages = [...?(body['messages'] as List<dynamic>?)?.cast<Map<String, dynamic>>()];
    final breakdown = body['breakdown'] as Map<String, dynamic>?;
    // Разговор о переписке начинается со скриншота или с разбора, о котором коуч ещё ничего не сказал.
    final isAboutNewChat = hasScreenshot || (breakdown != null && messages.isEmpty);
    if (text.isEmpty && !isAboutNewChat) {
      throw const NetworkError(NetworkErrorCode.logical, statusCode: 400, message: 'The message is empty');
    }

    await Future<void>.delayed(generationTime);

    final suggested = [
      for (final message in messages)
        if ((message['suggestion'] as Map<String, dynamic>?)?['text'] case final String line) line,
    ];
    final partner = hasScreenshot
        ? _nika['name'] as String
        : (body['chat'] as Map<String, dynamic>?)?['name'] as String? ??
              (breakdown?['partner'] as Map<String, dynamic>?)?['name'] as String?;
    final reply = _reply(
      text: text.toLowerCase(),
      hasChat: isAboutNewChat,
      topic: suggested.isEmpty ? null : _topicOfLine(suggested.last),
      used: suggested,
      partner: partner,
    );

    return {
      'id': 'coach-${DateTime.now().microsecondsSinceEpoch}',
      'text': reply.advice,
      'suggestion': {'text': reply.line, 'why': ?reply.why},
      'quick_replies': reply.quickReplies,
      'chat': ?(hasScreenshot ? _nika : null),
    };
  }

  /// Тема, к которой относится предложенное сообщение: заготовки в темах не повторяются.
  static String? _topicOfLine(String line) => _topics.entries
      .where((topic) => topic.value.lines.contains(line) || topic.value.bolder == line)
      .map((topic) => topic.key)
      .firstOrNull;

  /// Новая переписка — всегда разговор о ней; иначе «ещё вариант» и «смелее» — по последней теме,
  /// а остальное — новая тема по словам из сообщения.
  static _Reply _reply({
    required String text,
    required bool hasChat,
    required String? topic,
    required List<String> used,
    required String? partner,
  }) {
    final current = topic == null ? null : _topics[topic];
    if (!hasChat && topic != null && current != null) {
      if (text.contains('bolder')) {
        return (
          topic: topic,
          advice: 'Bolder it is — say what you want and make it easy to say yes:',
          line: current.bolder,
          why: null,
          quickReplies: const ['Give me another option', 'What if there’s no reply?'],
        );
      }
      if (text.contains('another')) {
        final previous = used.isEmpty ? null : used.last;
        final line = current.lines.firstWhere(
          (line) => !used.contains(line),
          orElse: () => current.lines.firstWhere((line) => line != previous, orElse: () => current.lines.first),
        );
        return (
          topic: topic,
          advice: 'Here’s another way to play it:',
          line: line,
          why: null,
          quickReplies: current.quickReplies,
        );
      }
    }

    final key = hasChat ? 'chat' : _topicOf(text);
    final next = _topics[key]!;
    return (
      topic: key,
      advice: next.advice.replaceAll('{name}', partner ?? 'They'),
      line: next.lines.firstWhere((line) => !used.contains(line), orElse: () => next.lines.first),
      why: next.why,
      quickReplies: next.quickReplies,
    );
  }

  static String _topicOf(String text) {
    bool mentions(List<String> words) => words.any(text.contains);
    if (mentions(['no reply', 'doesn’t reply', 'doesn\'t reply', 'don’t reply', 'don\'t reply', 'no answer'])) {
      return 'no_reply';
    }
    if (mentions(['stopped replying', 'stopped texting', 'not replying', 'ghost', 'left on read', 'went quiet'])) {
      return 'stopped_replying';
    }
    if (mentions(['ask them out', 'ask her out', 'ask him out', 'ask out', 'go out', 'a date', 'meet up'])) {
      return 'ask_out';
    }
    if (mentions(['start a chat', 'start the chat', 'first message', 'opener', 'open with'])) return 'start_chat';
    return 'general';
  }

  /// Что сервер «прочитал» на скриншоте переписки — пример из Figma.
  static const _nika = {'name': 'Nika', 'age': 28, 'verdict': 'Nika is into this — and doing most of the work.'};

  /// Ответы на «Should I ask them out?» и на переписку с Nika — из Figma, остальные написаны для моков.
  static const _topics = <String, _Topic>{
    'ask_out': (
      advice:
          'Good instinct — chats burn out when they drag. Anchor the invite in something you already talked about, '
          'and give two easy options:',
      lines: [
        'coffee thursday or a walk this weekend — which sounds more like you?',
        'okay, this needs to continue in person. drinks this week?',
        'you’ve sold me on that taco place. saturday?',
      ],
      bolder: 'let’s take this offline. coffee thursday — i’ll pick the place',
      why: null,
      quickReplies: ['Make it bolder', 'Give me another option'],
    ),
    'stopped_replying': (
      advice:
          'It happens, and it’s usually timing, not you. One light message that’s easy to answer is worth a shot — '
          'then let it be:',
      lines: [
        'no pressure — but i still need your verdict on that thing we were debating',
        'saw a dog in a tiny raincoat and thought of you. how’s your week going?',
      ],
      bolder: 'i liked talking to you, so i’ll just say it: up for picking this back up over coffee?',
      why: 'Easy to answer, and it doesn’t ask why they went quiet.',
      quickReplies: ['Make it bolder', 'Give me another option', 'What if there’s no reply?'],
    ),
    'start_chat': (
      advice:
          'Skip the “hey” — it’s the easiest message to ignore. Open with something from their profile, '
          'or a question that’s fun to answer:',
      lines: [
        'okay, settle a debate for me: breakfast for dinner — elite or chaotic?',
        'your profile has big weekend energy. what was the best one lately?',
      ],
      bolder: 'you look like trouble in the best way. prove me right?',
      why: null,
      quickReplies: ['Make it bolder', 'Give me another option'],
    ),
    'chat': (
      advice:
          'I read your chat. {name} is putting in most of the effort, and the last message is an open door. '
          'Pick up exactly that:',
      lines: [
        'sounds like the good kind of escape. which mountains — and what would get you back down?',
        'okay, now i need the whole mountain story. who talked who into it?',
      ],
      bolder: 'you, a mountain and that tent? count me in. when are you going back?',
      why: 'It answers the last message and hands the next question back.',
      quickReplies: ['Give me another option', 'Make it bolder', 'What if there’s no reply?'],
    ),
    'no_reply': (
      advice:
          'Give it a few days. One light follow-up is plenty — after that, silence is an answer too, '
          'and it’s not a verdict on you. If you do follow up:',
      lines: [
        'no rush — just didn’t want this to end on a cliffhanger',
        'still curious how that story ends, whenever you’re around',
      ],
      bolder: 'i’d still love that coffee. last call — your move',
      why: null,
      quickReplies: ['Give me another option', 'Make it bolder'],
    ),
    'general': (
      advice: 'Got it. Keep it light, show you were listening, and end with something easy to answer. Something like:',
      lines: [
        'wait, that sounds like a story. what happened next?',
        'okay, i need the full version of this. start from the beginning',
      ],
      bolder: 'honestly, this deserves a drink and the full story. this week?',
      why: null,
      quickReplies: ['Make it bolder', 'Give me another option'],
    ),
  };
}
