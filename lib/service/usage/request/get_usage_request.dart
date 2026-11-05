import 'package:dating_assistant/transport/api_request.dart';

/// Сколько бесплатных генераций потрачено и сколько можно за неделю.
class GetUsageRequest extends ApiRequest {
  const GetUsageRequest();

  @override
  String get path => '/api/v1/usage';
}
