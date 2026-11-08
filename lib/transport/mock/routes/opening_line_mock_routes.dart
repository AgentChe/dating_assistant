import 'package:dating_assistant/transport/mock/mock_database.dart';
import 'package:dating_assistant/transport/mock/mock_request.dart';
import 'package:dating_assistant/transport/mock/routes/usage_mock_routes.dart';
import 'package:dating_assistant/transport/network_error.dart';

/// Первые фразы. Мок не читает скриншот анкеты: любую считает анкетой Nika из Figma.
/// Фразы — заготовки по остроте; с именем и интересами мэтча подставляет их.
///
/// Фразы для одного мэтча — сессия: в истории она одна запись с последней фразой, а предложенные
/// в ней фразы не повторяются.
class OpeningLineMockRoutes {
  OpeningLineMockRoutes(this._database, {required this.generationTime});

  static const _key = 'opening_line_sessions';

  final MockDatabase _database;

  /// Сколько «думает» нейросеть.
  final Duration generationTime;

  Map<String, MockHandler> get routes => {
    'POST /api/v1/opening-lines': _generate,
    'GET /api/v1/opening-lines/:id': _session,
  };

  /// Сессии для истории: последняя фраза и для кого она.
  static List<Map<String, dynamic>> historyItems(MockDatabase database) => [
    for (final MapEntry(key: id, value: session as Map<String, dynamic>) in (database.read(_key) ?? {}).entries)
      {
        'type': 'opening_line',
        'id': id,
        'updated_at': session['updated_at'],
        'preview': (session['lines'] as List<dynamic>).last,
        if ((session['match'] as Map<String, dynamic>?)?['name'] case final String name)
          'partner': {'name': name, 'age': ?(session['match'] as Map<String, dynamic>)['age']},
      },
  ];

  Future<Map<String, dynamic>> _generate(MockRequest request) async {
    final body = request.body;
    final sessions = _database.read(_key) ?? <String, dynamic>{};
    final sessionId = body['session_id'] as String?;
    final session = sessionId == null ? null : sessions[sessionId] as Map<String, dynamic>?;
    if (sessionId != null && session == null) {
      throw const NetworkError(NetworkErrorCode.logical, statusCode: 404, message: 'No such session');
    }
    if (!await UsageMockRoutes.consumeGeneration(_database)) {
      throw const NetworkError(
        NetworkErrorCode.logical,
        statusCode: 402,
        message: 'No free generations left this week',
      );
    }

    await Future<void>.delayed(generationTime);

    final fromScreenshot = (body['profile_screenshot'] as String? ?? '').isNotEmpty;
    final match = fromScreenshot
        ? _nika
        : body['match'] as Map<String, dynamic>? ?? session?['match'] as Map<String, dynamic>?;
    final previous = {...?(body['previous_lines'] as List<dynamic>?), ...?(session?['lines'] as List<dynamic>?)};
    final candidates = [
      if (fromScreenshot) 'fair. what would have to happen down here for you to come back?',
      ..._personalized(match, body['spice'] as String? ?? 'warm'),
    ];

    final now = DateTime.now().toUtc();
    final id = sessionId ?? 'opening-lines-${now.microsecondsSinceEpoch}';
    final line = {
      'id': 'line-${now.microsecondsSinceEpoch}',
      'session_id': id,
      'line': candidates.firstWhere((line) => !previous.contains(line), orElse: () => candidates.first),
    };
    sessions[id] = {
      'match': ?match,
      'lines': [...?(session?['lines'] as List<dynamic>?), line['line']],
      'latest': line,
      'updated_at': now.toIso8601String(),
    };
    await _database.write(_key, sessions);

    return {...line, 'match': ?(fromScreenshot ? match : null)};
  }

  /// Последняя фраза сессии и всё, что известно о мэтче, — чтобы продолжить из истории.
  Map<String, dynamic> _session(MockRequest request) {
    final session = (_database.read(_key) ?? {})[request.params['id']] as Map<String, dynamic>?;
    if (session == null) {
      throw const NetworkError(NetworkErrorCode.logical, statusCode: 404, message: 'No such session');
    }
    return {...session['latest'] as Map<String, dynamic>, 'match': ?session['match']};
  }

  /// Заготовки нужной остроты; с интересом мэтча — сначала про него.
  static List<String> _personalized(Map<String, dynamic>? match, String spice) {
    final lines = _lines[spice] ?? _lines['warm']!;
    final name = (match?['name'] as String?)?.trim();
    final interest = (match?['interests'] as String?)?.split(RegExp('[,.\n]')).first.trim().toLowerCase();
    return [
      if (interest != null && interest.isNotEmpty)
        for (final line in lines.withInterest)
          line.replaceAll('{interest}', interest).replaceAll('{name}', name == null || name.isEmpty ? 'hey' : name),
      ...lines.generic,
    ];
  }

  static const _nika = {'name': 'Nika', 'age': 28, 'interests': 'Into mountains, not into small talk'};

  static const _lines = {
    'soft': (
      withInterest: [
        '{name}, {interest} caught my eye. how did you get into it?',
        '{interest} is such a good pick. what’s your favorite part?',
      ],
      generic: [
        'hi! your profile made me smile. how’s your week going?',
        'you seem like someone with good stories. what’s the latest one?',
      ],
    ),
    'warm': (
      withInterest: [
        '{name}, {interest} on your profile. favorite memory with it?',
        'so {interest}, huh? convince me i should try it',
      ],
      generic: [
        'okay, i have to ask: perfect sunday, go',
        'i was going to say something clever, then got distracted by your smile',
      ],
    ),
    'playful': (
      withInterest: [
        '{interest}? bold choice. i’m listening, {name}',
        'be honest, how competitive are you about {interest}?',
      ],
      generic: [
        'rate your texting skills 1 to 10. be honest, i’m judging',
        'coffee or cocktails? there’s a right answer',
      ],
    ),
    'bold': (
      withInterest: [
        '{name}, teach me {interest} and the first round is on me',
        'anyone into {interest} has my attention. tell me more',
      ],
      generic: [
        'let’s skip the small talk. what are you actually looking for here?',
        'you’re cute. that’s the opener. your turn',
      ],
    ),
    'spicy': (
      withInterest: [
        '{interest} and that smile? unfair, {name}',
        '{name}, you had me at {interest}. what else should i know?',
      ],
      generic: ['i was going to play it cool. didn’t work', 'careful, i’m better in person than over text'],
    ),
  };
}
