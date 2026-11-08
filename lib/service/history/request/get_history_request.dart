import 'package:dating_assistant/transport/api_request.dart';

/// Вся история пользователя, новые записи сверху. Без пагинации.
class GetHistoryRequest extends ApiRequest {
  const GetHistoryRequest();

  @override
  String get path => '/api/v1/history';
}
