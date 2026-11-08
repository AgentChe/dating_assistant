import 'package:dating_assistant/service/coach/model/coach_tone.dart';

// Подписи тонов коуча из Figma; когда подключим локализацию, переедут в строки.

extension CoachToneTitle on CoachTone {
  String get emoji => switch (this) {
    CoachTone.auto => '✦',
    CoachTone.flirt => '😏',
    CoachTone.intrigue => '🔍',
    CoachTone.connect => '🫶',
  };

  String get title => switch (this) {
    CoachTone.auto => 'Auto',
    CoachTone.flirt => 'Flirt',
    CoachTone.intrigue => 'Intrigue',
    CoachTone.connect => 'Connect',
  };
}
