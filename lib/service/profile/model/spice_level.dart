import 'package:dating_assistant/service/profile/model/dating_goal.dart';

/// «Острота» сообщений: пять ступеней от мягких до дерзких.
enum SpiceLevel {
  soft,
  warm,
  playful,
  bold,
  spicy
  ;

  /// Номер ступени от 1 до 5.
  int get level => index + 1;

  /// С какой ступени начинать, пока пользователь не выбрал сам.
  static SpiceLevel defaultFor(DatingGoal goal) => switch (goal) {
    DatingGoal.relationship || DatingGoal.unsure => SpiceLevel.warm,
    DatingGoal.casual => SpiceLevel.playful,
    DatingGoal.friends => SpiceLevel.soft,
  };
}
