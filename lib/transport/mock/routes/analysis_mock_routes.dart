import 'package:dating_assistant/transport/mock/mock_database.dart';
import 'package:dating_assistant/transport/mock/mock_request.dart';
import 'package:dating_assistant/transport/mock/routes/usage_mock_routes.dart';
import 'package:dating_assistant/transport/network_error.dart';

/// Разбор переписки. Мок не читает скриншот: на любую картинку отвечает примером из Figma
/// и сохраняет разбор для будущей истории — без самой картинки.
class AnalysisMockRoutes {
  AnalysisMockRoutes(this._database, {required this.generationTime});

  static const _key = 'analyses';

  final MockDatabase _database;

  /// Сколько «думает» нейросеть — чтобы на моках было видно сканирование.
  final Duration generationTime;

  Map<String, MockHandler> get routes => {'POST /api/v1/analyses': _analyze};

  Future<Map<String, dynamic>> _analyze(MockRequest request) async {
    if ((request.body['screenshot'] as String? ?? '').isEmpty) {
      throw const NetworkError(NetworkErrorCode.logical, statusCode: 400, message: 'The screenshot is empty');
    }
    if (!await UsageMockRoutes.consumeGeneration(_database)) {
      throw const NetworkError(
        NetworkErrorCode.logical,
        statusCode: 402,
        message: 'No free generations left this week',
      );
    }

    await Future<void>.delayed(generationTime);

    final now = DateTime.now().toUtc();
    final analysis = {'id': 'analysis-${now.microsecondsSinceEpoch}', 'created_at': now.toIso8601String(), ..._example};
    final saved = _database.read(_key)?['items'] as List<dynamic>? ?? const [];
    await _database.write(_key, {
      'items': [analysis, ...saved],
    });
    return analysis;
  }

  /// Разбор из макета: переписка с Nika про палатку в горах.
  static const _example = {
    'partner': {'name': 'Nika', 'age': 28},
    'read': {'emoji': '😍', 'verdict': 'Nika is into this', 'detail': 'and doing most of the work.'},
    'interest': {
      'them': {'level': 4, 'label': 'Warm'},
      'you': {'level': 3, 'label': 'Mixed'},
    },
    'word_share': {'them': 70, 'you': 30},
    'going_well': [
      {'title': 'Asked about you', 'proof': '“is that tent real…”'},
      {'title': 'Opened up', 'proof': '“honestly don’t want…”'},
    ],
    'watch_out': [
      {'title': 'You didn’t ask back', 'proof': 'Your only reply'},
      {'title': 'Nika leads for now', 'proof': '2 of 3 messages'},
    ],
    'topics': [
      {'emoji': '🏔️', 'title': 'Mountains'},
      {'emoji': '⛺', 'title': 'The tent'},
      {'emoji': '🧳', 'title': 'Getaways'},
    ],
    'vibe': {
      'them': {'emoji': '😜', 'label': 'Playful'},
      'you': {'emoji': '😌', 'label': 'Laid-back'},
    },
    'heading': {'label': 'Warming up', 'trend': 'up', 'detail': 'The last message is the most personal yet.'},
    'next_move': 'Ask about the mountains. Give Nika a reason to keep talking.',
  };
}
