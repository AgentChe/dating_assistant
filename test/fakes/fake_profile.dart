import 'package:dating_assistant/service/profile/model/age_range.dart';
import 'package:dating_assistant/service/profile/model/dating_goal.dart';
import 'package:dating_assistant/service/profile/model/gender.dart';
import 'package:dating_assistant/service/profile/model/hardest_part.dart';
import 'package:dating_assistant/service/profile/model/profile.dart';
import 'package:dating_assistant/service/profile/model/spice_level.dart';
import 'package:dating_assistant/service/profile/model/voice.dart';
import 'package:dating_assistant/service/profile/profile_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

/// Профиль после онбординга — как в макете профиля.
const fakeProfile = Profile(
  name: 'Alex',
  goal: DatingGoal.relationship,
  gender: Gender.woman,
  ageRange: AgeRange.from25To34,
  hardestParts: [HardestPart.keepingItGoing],
  voice: Voice({VoiceTrait.lowercase, VoiceTrait.direct}),
  spice: SpiceLevel.warm,
);

/// ProfileManager на SharedPreferences в памяти с уже сохранённым [profile].
Future<ProfileManager> fakeProfileManager({Profile? profile = fakeProfile}) async {
  SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
  final preferences = await SharedPreferencesWithCache.create(cacheOptions: const SharedPreferencesWithCacheOptions());
  final profileManager = ProfileManager(preferences);
  if (profile != null) await profileManager.save(profile);
  return profileManager;
}
