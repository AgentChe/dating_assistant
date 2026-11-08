import 'package:dating_assistant/transport/api_request.dart';

/// Сохранённый разбор — открыть его из истории.
class GetAnalysisRequest extends ApiRequest {
  const GetAnalysisRequest(this.id);

  final String id;

  @override
  String get path => '/api/v1/analyses/$id';
}
