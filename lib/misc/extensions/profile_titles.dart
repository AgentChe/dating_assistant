import 'package:dating_assistant/service/profile/model/dating_goal.dart';
import 'package:dating_assistant/service/profile/model/gender.dart';

// Временные подписи: заменим строками из Figma, когда подключим локализацию.

extension GenderTitle on Gender {
  String get title => switch (this) {
    Gender.male => 'Male',
    Gender.female => 'Female',
  };
}

extension DatingGoalTitle on DatingGoal {
  String get title => switch (this) {
    DatingGoal.relationship => 'Serious relationship',
    DatingGoal.casual => 'Something casual',
    DatingGoal.friendship => 'Friendship',
    DatingGoal.unsure => 'Not sure yet',
  };
}
