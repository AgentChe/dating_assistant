import 'package:dating_assistant/transport/mock/mock_database.dart';
import 'package:dating_assistant/transport/mock/mock_request.dart';
import 'package:dating_assistant/transport/mock/routes/usage_mock_routes.dart';
import 'package:dating_assistant/transport/network_error.dart';

/// Первые фразы. Мок не читает скриншот анкеты: любую считает анкетой Nika из Figma.
/// Фразы — заготовки по остроте; с именем и интересами мэтча подставляет их.
/// Сервер ничего не помнит: уже предложенные фразы присылает клиент.
class OpeningLineMockRoutes {
  OpeningLineMockRoutes(this._database, {required this.generationTime});

  /// Тут только счётчик бесплатных генераций.
  final MockDatabase _database;

  /// Сколько «думает» нейросеть.
  final Duration generationTime;

  Map<String, MockHandler> get routes => {'POST /api/v1/opening-lines': _generate};

  Future<Map<String, dynamic>> _generate(MockRequest request) async {
    if (!await UsageMockRoutes.consumeGeneration(_database)) {
      throw const NetworkError(
        NetworkErrorCode.logical,
        statusCode: 402,
        message: 'No free generations left this week',
      );
    }

    await Future<void>.delayed(generationTime);

    final body = request.body;
    final fromScreenshot = (body['profile_screenshot'] as String? ?? '').isNotEmpty;
    final match = fromScreenshot ? _nika : body['match'] as Map<String, dynamic>?;
    final previous = {...?(body['previous_lines'] as List<dynamic>?)};
    final candidates = [
      if (fromScreenshot) 'fair. what would have to happen down here for you to come back?',
      ..._personalized(match, body['spice'] as String? ?? 'warm'),
    ];

    return {
      'id': 'line-${DateTime.now().microsecondsSinceEpoch}',
      'line': candidates.firstWhere((line) => !previous.contains(line), orElse: () => candidates.first),
      'match': ?(fromScreenshot ? match : null),
    };
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
