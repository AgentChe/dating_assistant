import 'package:dating_assistant/service/history/model/history_item.dart';
import 'package:dating_assistant/service/history/request/get_history_request.dart';
import 'package:dating_assistant/transport/api_transport.dart';

/// История (аналог XxxManager из Swift-проектов): разборы, разговоры с коучем и первые фразы.
/// Хранит её сервер; открыть запись — дело её домена (AnalysisManager, CoachManager, OpeningLineManager).
class HistoryManager {
  HistoryManager(this._transport);

  final ApiTransport _transport;

  /// Новые сверху. Бросает NetworkError.
  Future<List<HistoryItem>> obtainHistory() async {
    final json = await _transport.callServerApi(const GetHistoryRequest());
    return [
      for (final item in (json['items'] as List<dynamic>).cast<Map<String, dynamic>>()) ?HistoryItem.fromJson(item),
    ];
  }
}
