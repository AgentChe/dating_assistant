import 'package:dating_assistant/service/profile/model/dating_goal.dart';
import 'package:dating_assistant/service/profile/model/gender.dart';
import 'package:dating_assistant/service/profile/model/profile.dart';
import 'package:dating_assistant/service/profile/request/create_profile_request.dart';
import 'package:dating_assistant/service/profile/request/obtain_profile_request.dart';
import 'package:dating_assistant/service/session/session_manager.dart';
import 'package:dating_assistant/transport/api_transport.dart';

/// Работа с профилем пользователя (аналог ProfileManager из Swift-проектов).
class ProfileManager {
  ProfileManager({required ApiTransport transport, required SessionManager sessionManager})
    : _transport = transport,
      _sessionManager = sessionManager;

  final ApiTransport _transport;

  final SessionManager _sessionManager;

  /// Создаёт пользователя по ответам онбординга и сохраняет его сессию.
  Future<Profile> create({required Gender gender, required int age, required DatingGoal datingGoal}) async {
    final request = CreateProfileRequest(gender: gender, age: age, datingGoal: datingGoal);
    final response = await _transport.callServerApi(request);
    await _sessionManager.save(token: response['token'] as String);
    return Profile.fromJson(response['profile'] as Map<String, dynamic>);
  }

  Future<Profile> obtain() async {
    final response = await _transport.callServerApi(const ObtainProfileRequest());
    return Profile.fromJson(response['profile'] as Map<String, dynamic>);
  }
}
