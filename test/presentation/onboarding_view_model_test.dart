import 'package:dating_assistant/presentation/splash/onboarding/onboarding_content.dart';
import 'package:dating_assistant/presentation/splash/onboarding/onboarding_view_model.dart';
import 'package:dating_assistant/service/profile/model/age_range.dart';
import 'package:dating_assistant/service/profile/model/dating_goal.dart';
import 'package:dating_assistant/service/profile/model/gender.dart';
import 'package:dating_assistant/service/profile/model/hardest_part.dart';
import 'package:dating_assistant/service/profile/model/spice_level.dart';
import 'package:dating_assistant/service/profile/model/voice.dart';
import 'package:dating_assistant/service/profile/profile_manager.dart';
import 'package:dating_assistant/service/session/session_manager.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  late ProfileManager profileManager;
  late OnboardingViewModel viewModel;

  setUp(() async {
    SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
    final preferences = await SharedPreferencesWithCache.create(
      cacheOptions: const SharedPreferencesWithCacheOptions(),
    );
    profileManager = ProfileManager(preferences);
    viewModel = OnboardingViewModel(
      profileManager: profileManager,
      // Без ключа OtterScale подписки нет — после плана откроется пейгейт.
      sessionManager: SessionManager(host: 'https://otter.test', apiKey: ''),
    );
  });

  /// Проходит онбординг до карточек голоса.
  void answerAboutYou() {
    viewModel
      ..next()
      ..changeName('  Alex ')
      ..next()
      ..selectGoal(DatingGoal.casual)
      ..next()
      ..selectGender(Gender.woman)
      ..selectAgeRange(AgeRange.from25To34)
      ..next()
      ..toggleHardestPart(HardestPart.startingConversation)
      ..toggleHardestPart(HardestPart.askingThemOut)
      ..next()
      ..next();
  }

  test('does not continue until the step is answered', () {
    viewModel.next();
    expect(viewModel.step, OnboardingStep.name);

    viewModel.next();
    expect(viewModel.step, OnboardingStep.name);

    viewModel.skipName();
    expect(viewModel.step, OnboardingStep.goal);
    expect(viewModel.name, isNull);

    viewModel.next();
    expect(viewModel.step, OnboardingStep.goal);
  });

  test('builds the voice from the swipes and saves the profile', () async {
    answerAboutYou();
    expect(viewModel.step, OnboardingStep.voice);

    viewModel
      ..answerVoice(isMe: false)
      ..answerVoice(isMe: true)
      ..answerVoice(isMe: false);
    expect(viewModel.step, OnboardingStep.yourVoice);
    expect(viewModel.voice.traits, {VoiceTrait.emoji});

    viewModel
      ..next()
      ..selectTryItAnswer(OnboardingContent.tryItAnswers.first)
      ..next()
      ..next();
    expect(viewModel.step, OnboardingStep.building);

    await viewModel.completeBuilding();
    expect(viewModel.step, OnboardingStep.plan);
    expect(viewModel.startingPoint, StartingPoint.openingLine);

    final profile = profileManager.profile!;
    expect(profile.name, 'Alex');
    expect(profile.goal, DatingGoal.casual);
    expect(profile.gender, Gender.woman);
    expect(profile.ageRange, AgeRange.from25To34);
    expect(profile.hardestParts, [HardestPart.startingConversation, HardestPart.askingThemOut]);
    expect(profile.voice.traits, {VoiceTrait.emoji});
    expect(profile.spice, SpiceLevel.playful);

    final actions = <OnboardingAction>[];
    viewModel.actions.listen(actions.add);
    viewModel.next();
    await pumpEventQueue();
    expect(actions, [OnboardingAction.openPaygate]);
  });

  test('back undoes voice answers one card at a time', () {
    answerAboutYou();
    viewModel
      ..answerVoice(isMe: true)
      ..answerVoice(isMe: true)
      ..answerVoice(isMe: true);
    expect(viewModel.step, OnboardingStep.yourVoice);

    viewModel.back();
    expect(viewModel.step, OnboardingStep.voice);
    expect(viewModel.voiceSampleIndex, 2);

    viewModel
      ..back()
      ..back();
    expect(viewModel.voiceSampleIndex, 0);

    viewModel.back();
    expect(viewModel.step, OnboardingStep.insight);
  });

  test('fills the chapters of the progress bar', () {
    expect(viewModel.progress, 0);

    answerAboutYou();
    expect(viewModel.progress, 1.25);

    viewModel
      ..answerVoice(isMe: true)
      ..answerVoice(isMe: true)
      ..answerVoice(isMe: true);
    expect(viewModel.progress, 2);
  });
}
