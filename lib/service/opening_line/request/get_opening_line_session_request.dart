import 'package:dating_assistant/transport/api_request.dart';

/// Последняя фраза сессии — чтобы продолжить её из истории.
class GetOpeningLineSessionRequest extends ApiRequest {
  const GetOpeningLineSessionRequest(this.sessionId);

  final String sessionId;

  @override
  String get path => '/api/v1/opening-lines/$sessionId';
}
