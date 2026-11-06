import 'package:dating_assistant/presentation/main/profile/profile_view_model.dart';
import 'package:dating_assistant/presentation/splash/paygate/paygate_view_model.dart';
import 'package:dating_assistant/service/profile/model/age_range.dart';
import 'package:dating_assistant/service/profile/model/dating_goal.dart';
import 'package:dating_assistant/service/profile/model/gender.dart';
import 'package:dating_assistant/service/profile/model/spice_level.dart';
import 'package:dating_assistant/service/profile/model/voice.dart';
import 'package:dating_assistant/service/profile/profile_manager.dart';
import 'package:dating_assistant/service/purchase/model/purchase_result.dart';
import 'package:dating_assistant/service/session/model/subscription.dart';
import 'package:dating_assistant/service/usage/model/usage.dart';
import 'package:dating_assistant/service/usage/usage_mediator.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_managers.dart';
import '../fakes/fake_profile.dart';

void main() {
  late ProfileManager profileManager;
  late FakeSessionManager sessionManager;
  late FakePurchaseManager purchaseManager;
  late FakeUsageManager usageManager;
  late UsageMediator usageMediator;

  ProfileViewModel makeViewModel() => ProfileViewModel(
    profileManager: profileManager,
    sessionManager: sessionManager,
    purchaseManager: purchaseManager,
    usageManager: usageManager,
    usageMediator: usageMediator,
    yearlyId: 'yearly',
    weeklyId: 'weekly',
  );

  setUp(() async {
    profileManager = await fakeProfileManager();
    sessionManager = FakeSessionManager();
    purchaseManager = FakePurchaseManager();
    usageManager = FakeUsageManager(usage: const Usage(used: 2, limit: 3));
    usageMediator = UsageMediator();
  });

  test('the plan refreshes when a generation is spent on another screen', () async {
    final viewModel = makeViewModel();
    await viewModel.loadPlan();
    expect((viewModel.plan as FreePlan).usage!.left, 1);

    usageManager.usage = const Usage(used: 3, limit: 3);
    usageMediator.notifyGenerationUsed();
    await pumpEventQueue();

    expect((viewModel.plan as FreePlan).usage!.left, 0);
  });

  test('shows the profile saved on onboarding', () {
    final profile = makeViewModel().profile!;

    expect(profile.gender, Gender.woman);
    expect(profile.ageRange, AgeRange.from25To34);
    expect(profile.goal, DatingGoal.relationship);
    expect(profile.spice, SpiceLevel.warm);
  });

  test('a new spice is saved right away', () async {
    final viewModel = makeViewModel();

    await viewModel.selectSpice(SpiceLevel.bold);

    expect(viewModel.profile!.spice, SpiceLevel.bold);
    expect(profileManager.profile!.spice, SpiceLevel.bold);
  });

  test('About you changes are saved and keep the other answers', () async {
    final viewModel = makeViewModel();

    await viewModel.updateAboutYou((gender: Gender.man, ageRange: AgeRange.from35To44, goal: DatingGoal.casual));

    final saved = profileManager.profile!;
    expect(saved.gender, Gender.man);
    expect(saved.ageRange, AgeRange.from35To44);
    expect(saved.goal, DatingGoal.casual);
    expect(saved.name, 'Alex');
    expect(saved.spice, SpiceLevel.warm);
    expect(saved.voice.traits, {VoiceTrait.lowercase, VoiceTrait.direct});
    expect(viewModel.profile!.gender, Gender.man);
  });

  test('without a subscription the plan is free with the generations left', () async {
    final viewModel = makeViewModel();
    expect(viewModel.plan, isNull);

    await viewModel.loadPlan();

    final plan = viewModel.plan as FreePlan;
    expect(plan.usage!.left, 1);
    expect(plan.usage!.limit, 3);
  });

  test('the free plan still shows when the usage fails to load', () async {
    usageManager.error = Exception('offline');
    final viewModel = makeViewModel();

    await viewModel.loadPlan();

    expect((viewModel.plan as FreePlan).usage, isNull);
  });

  test('a trial subscription shows its end and the price', () async {
    sessionManager.isPlus = true;
    sessionManager.subscription = Subscription(
      productId: 'weekly',
      expiresAt: DateTime(2026, 9, 23),
      isTrial: true,
      willRenew: true,
    );
    final viewModel = makeViewModel();

    await viewModel.loadPlan();

    final plan = viewModel.plan as PlusPlan;
    expect(plan.subscription!.isTrial, isTrue);
    expect(plan.price, r'$7.99 per week');
  });

  test('a subscription to an unknown product has no price', () async {
    sessionManager.isPlus = true;
    sessionManager.subscription = Subscription(
      productId: 'legacy',
      expiresAt: DateTime(2026, 9, 23),
      isTrial: false,
      willRenew: true,
    );
    final viewModel = makeViewModel();

    await viewModel.loadPlan();

    expect((viewModel.plan as PlusPlan).price, isNull);
  });

  test('restore without purchases says there is nothing to restore', () async {
    purchaseManager.result = PurchaseResult.notSubscribed;
    final viewModel = makeViewModel();

    await viewModel.restore();

    expect(viewModel.failure, PaygateFailure.nothingToRestore);
    expect(viewModel.isRestoring, isFalse);
  });

  test('restored purchases turn the plan into Plus', () async {
    final viewModel = makeViewModel();
    await viewModel.loadPlan();
    expect(viewModel.plan, isA<FreePlan>());
    // OtterScale уже знает о восстановленной подписке.
    sessionManager.isPlus = true;

    await viewModel.restore();

    expect(viewModel.plan, isA<PlusPlan>());
    expect(viewModel.failure, isNull);
  });

  test('a failed restore shows the failure', () async {
    purchaseManager.error = Exception('store unavailable');
    final viewModel = makeViewModel();

    await viewModel.restore();

    expect(viewModel.failure, PaygateFailure.restoreFailed);
  });
}
