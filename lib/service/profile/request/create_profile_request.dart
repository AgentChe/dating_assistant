import 'package:dating_assistant/service/profile/model/dating_goal.dart';
import 'package:dating_assistant/service/profile/model/gender.dart';
import 'package:dating_assistant/transport/api_request.dart';

/// Создание анонимного пользователя по ответам онбординга. Ответ: `{token, profile}`.
class CreateProfileRequest extends ApiRequest {
  const CreateProfileRequest({required this.gender, required this.age, required this.datingGoal});

  final Gender gender;

  final int age;

  final DatingGoal datingGoal;

  @override
  String get path => '/api/v1/profile';

  @override
  HttpMethod get method => HttpMethod.post;

  @override
  Map<String, dynamic> get body => {'gender': gender.name, 'age': age, 'dating_goal': datingGoal.name};
}
