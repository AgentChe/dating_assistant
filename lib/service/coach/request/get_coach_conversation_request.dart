import 'package:dating_assistant/transport/api_request.dart';

/// Разговор с коучем целиком — продолжить его из истории.
class GetCoachConversationRequest extends ApiRequest {
  const GetCoachConversationRequest(this.id);

  final String id;

  @override
  String get path => '/api/v1/coach/conversations/$id';
}
