import 'package:dating_assistant/service/profile/model/age_range.dart';
import 'package:dating_assistant/service/profile/model/dating_goal.dart';
import 'package:dating_assistant/service/profile/model/gender.dart';
import 'package:dating_assistant/service/profile/model/hardest_part.dart';
import 'package:dating_assistant/service/profile/model/spice_level.dart';
import 'package:dating_assistant/service/profile/model/voice.dart';

// Подписи значений профиля из Figma; когда подключим локализацию, переедут в строки.

extension GenderTitle on Gender {
  String get title => switch (this) {
    Gender.man => 'Man',
    Gender.woman => 'Woman',
    Gender.nonBinary => 'Non-binary',
  };
}

extension AgeRangeTitle on AgeRange {
  String get title => switch (this) {
    AgeRange.from18To24 => '18–24',
    AgeRange.from25To34 => '25–34',
    AgeRange.from35To44 => '35–44',
    AgeRange.from45 => '45+',
  };
}

extension DatingGoalTitle on DatingGoal {
  String get emoji => switch (this) {
    DatingGoal.relationship => '💘',
    DatingGoal.casual => '🔥',
    DatingGoal.friends => '🤝',
    DatingGoal.unsure => '🤷',
  };

  String get title => switch (this) {
    DatingGoal.relationship => 'A relationship',
    DatingGoal.casual => 'Something casual',
    DatingGoal.friends => 'New friends',
    DatingGoal.unsure => 'Not sure yet',
  };

  /// Коротко — для профиля: «Looking for · Relationship».
  String get shortTitle => switch (this) {
    DatingGoal.relationship => 'Relationship',
    DatingGoal.casual => 'Casual',
    DatingGoal.friends => 'Friendship',
    DatingGoal.unsure => 'Not sure',
  };

  String get subtitle => switch (this) {
    DatingGoal.relationship => 'Someone to build something with',
    DatingGoal.casual => 'Fun, no pressure',
    DatingGoal.friends => 'People to hang out with',
    DatingGoal.unsure => 'Figuring it out as I go',
  };
}

extension HardestPartTitle on HardestPart {
  String get emoji => switch (this) {
    HardestPart.startingConversation => '😶',
    HardestPart.keepingItGoing => '🫠',
    HardestPart.knowingIfInterested => '🤔',
    HardestPart.whenTheyGoQuiet => '👻',
    HardestPart.askingThemOut => '📅',
  };

  String get title => switch (this) {
    HardestPart.startingConversation => 'Starting the conversation',
    HardestPart.keepingItGoing => 'Keeping it going',
    HardestPart.knowingIfInterested => 'Knowing if they’re into me',
    HardestPart.whenTheyGoQuiet => 'When they go quiet',
    HardestPart.askingThemOut => 'Asking them out',
  };
}

extension SpiceLevelTitle on SpiceLevel {
  String get title => switch (this) {
    SpiceLevel.soft => 'Soft',
    SpiceLevel.warm => 'Warm',
    SpiceLevel.playful => 'Playful',
    SpiceLevel.bold => 'Bold',
    SpiceLevel.spicy => 'Spicy',
  };

  /// Подпись под ползунком в профиле. В Figma есть только Warm, остальные — наши.
  String get description => switch (this) {
    SpiceLevel.soft => 'Sweet and friendly, no flirting',
    SpiceLevel.warm => 'Kind, a little flirty',
    SpiceLevel.playful => 'Teasing, clearly flirting',
    SpiceLevel.bold => 'Confident, says what they want',
    SpiceLevel.spicy => 'Daring, turns up the heat',
  };
}

extension VoiceTitle on Voice {
  /// Черты голоса для пилюль: «lowercase», «no emoji», «straight to the point».
  List<String> get traitTitles => [
    has(VoiceTrait.lowercase) ? 'lowercase' : 'proper caps',
    has(VoiceTrait.emoji) ? 'loves emoji' : 'no emoji',
    has(VoiceTrait.direct) ? 'straight to the point' : 'takes it slow',
  ];

  /// Коротко через запятую: «lowercase, no emoji, direct».
  String get summary => [
    has(VoiceTrait.lowercase) ? 'lowercase' : 'proper caps',
    has(VoiceTrait.emoji) ? 'emoji' : 'no emoji',
    has(VoiceTrait.direct) ? 'direct' : 'takes it slow',
  ].join(', ');
}
