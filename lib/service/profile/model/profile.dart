import 'package:dating_assistant/service/profile/model/dating_goal.dart';
import 'package:dating_assistant/service/profile/model/gender.dart';

/// Профиль пользователя — ответы с онбординга.
class Profile {
  const Profile({required this.gender, required this.age, required this.datingGoal});

  factory Profile.fromJson(Map<String, dynamic> json) => Profile(
    gender: Gender.values.byName(json['gender'] as String),
    age: json['age'] as int,
    datingGoal: DatingGoal.values.byName(json['dating_goal'] as String),
  );

  final Gender gender;

  final int age;

  final DatingGoal datingGoal;
}
