import 'package:dating_assistant/service/profile/model/age_range.dart';
import 'package:dating_assistant/service/profile/model/dating_goal.dart';
import 'package:dating_assistant/service/profile/model/gender.dart';
import 'package:dating_assistant/service/profile/model/hardest_part.dart';
import 'package:dating_assistant/service/profile/model/profile.dart';
import 'package:dating_assistant/service/profile/model/spice_level.dart';
import 'package:dating_assistant/service/profile/model/voice.dart';
import 'package:dating_assistant/service/profile/profile_manager.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  late SharedPreferencesWithCache preferences;
  late ProfileManager profileManager;

  setUp(() async {
    SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
    preferences = await SharedPreferencesWithCache.create(cacheOptions: const SharedPreferencesWithCacheOptions());
    profileManager = ProfileManager(preferences);
  });

  test('saves the profile and reads it back', () async {
    expect(profileManager.profile, isNull);

    await profileManager.save(
      const Profile(
        name: 'Alex',
        goal: DatingGoal.relationship,
        gender: Gender.nonBinary,
        ageRange: AgeRange.from25To34,
        hardestParts: [HardestPart.keepingItGoing, HardestPart.knowingIfInterested],
        voice: Voice({VoiceTrait.lowercase, VoiceTrait.direct}),
        spice: SpiceLevel.warm,
      ),
    );

    final profile = profileManager.profile!;
    expect(profile.name, 'Alex');
    expect(profile.goal, DatingGoal.relationship);
    expect(profile.gender, Gender.nonBinary);
    expect(profile.ageRange, AgeRange.from25To34);
    expect(profile.hardestParts, [HardestPart.keepingItGoing, HardestPart.knowingIfInterested]);
    expect(profile.voice.traits, {VoiceTrait.lowercase, VoiceTrait.direct});
    expect(profile.spice, SpiceLevel.warm);
  });

  test('ignores a profile saved by an older model', () async {
    await preferences.setString('profile', '{"gender": "female", "age": 27}');

    expect(profileManager.profile, isNull);
  });
}
