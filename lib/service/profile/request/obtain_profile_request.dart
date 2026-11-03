import 'package:dating_assistant/transport/api_request.dart';

/// Профиль текущего пользователя. Ответ: `{profile}`.
class ObtainProfileRequest extends ApiRequest {
  const ObtainProfileRequest();

  @override
  String get path => '/api/v1/profile';
}
