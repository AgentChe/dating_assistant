import 'package:dating_assistant/service/profile/model/age_range.dart';
import 'package:dating_assistant/service/profile/model/dating_goal.dart';
import 'package:dating_assistant/service/profile/model/gender.dart';
import 'package:dating_assistant/service/profile/model/hardest_part.dart';
import 'package:dating_assistant/service/profile/model/spice_level.dart';
import 'package:dating_assistant/service/profile/model/voice.dart';

/// Профиль пользователя — ответы с онбординга.
class Profile {
  const Profile({
    this.name,
    required this.goal,
    required this.gender,
    required this.ageRange,
    required this.hardestParts,
    required this.voice,
    required this.spice,
  });

  factory Profile.fromJson(Map<String, dynamic> json) => Profile(
    name: json['name'] as String?,
    goal: DatingGoal.values.byName(json['goal'] as String),
    gender: Gender.values.byName(json['gender'] as String),
    ageRange: AgeRange.values.byName(json['age_range'] as String),
    hardestParts: [
      for (final name in json['hardest_parts'] as List<dynamic>) HardestPart.values.byName(name as String),
    ],
    voice: Voice.fromJson(json['voice'] as List<dynamic>),
    spice: SpiceLevel.values.byName(json['spice'] as String),
  );

  /// Как обращаться к пользователю; null — шаг с именем пропущен.
  final String? name;

  final DatingGoal goal;

  final Gender gender;

  final AgeRange ageRange;

  final List<HardestPart> hardestParts;

  final Voice voice;

  /// Острота сообщений по умолчанию («Default spice» в профиле).
  final SpiceLevel spice;

  Map<String, dynamic> toJson() => {
    'name': name,
    'goal': goal.name,
    'gender': gender.name,
    'age_range': ageRange.name,
    'hardest_parts': [for (final part in hardestParts) part.name],
    'voice': voice.toJson(),
    'spice': spice.name,
  };
}
