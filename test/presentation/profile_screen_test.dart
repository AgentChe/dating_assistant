import 'package:dating_assistant/misc/custom_views/pill_chip.dart';
import 'package:dating_assistant/presentation/main/profile/profile_screen.dart';
import 'package:dating_assistant/presentation/main/profile/profile_view_model.dart';
import 'package:dating_assistant/presentation/main/profile/views/spice_card.dart';
import 'package:dating_assistant/service/profile/model/age_range.dart';
import 'package:dating_assistant/service/profile/model/dating_goal.dart';
import 'package:dating_assistant/service/profile/model/gender.dart';
import 'package:dating_assistant/service/profile/model/spice_level.dart';
import 'package:dating_assistant/service/profile/profile_manager.dart';
import 'package:dating_assistant/service/session/model/subscription.dart';
import 'package:dating_assistant/service/usage/model/usage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_managers.dart';
import '../fakes/fake_profile.dart';

void main() {
  late ProfileManager profileManager;
  late FakeSessionManager sessionManager;

  setUp(() async {
    profileManager = await fakeProfileManager();
    sessionManager = FakeSessionManager();
  });

  Future<void> openProfile(WidgetTester tester) async {
    tester.view
      ..physicalSize = const Size(1284, 2778)
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final viewModel = ProfileViewModel(
      profileManager: profileManager,
      sessionManager: sessionManager,
      purchaseManager: FakePurchaseManager(),
      usageManager: FakeUsageManager(usage: const Usage(used: 2, limit: 3)),
      yearlyId: 'yearly',
      weeklyId: 'weekly',
    );
    await tester.pumpWidget(MaterialApp(home: ProfileScreen(viewModel: viewModel)));
    await tester.pumpAndSettle();
  }

  Future<void> tapChip(WidgetTester tester, String label) async {
    await tester.tap(find.widgetWithText(PillChip, label));
    await tester.pump();
  }

  testWidgets('shows the answers from onboarding and the free plan', (tester) async {
    await openProfile(tester);

    expect(find.text('Woman'), findsOneWidget);
    expect(find.text('25–34'), findsOneWidget);
    expect(find.text('Relationship'), findsOneWidget);
    expect(find.text('Warm'), findsOneWidget);
    expect(find.text('Kind, a little flirty'), findsOneWidget);
    expect(find.text('1 of 3 free generations left'), findsOneWidget);
    expect(find.text('Go unlimited'), findsOneWidget);
  });

  testWidgets('About you is edited in the sheet and saved', (tester) async {
    await openProfile(tester);

    await tester.tap(find.text('Age'));
    await tester.pumpAndSettle();
    expect(find.text('We use it to tune how your lines sound.'), findsOneWidget);

    await tapChip(tester, 'Man');
    await tapChip(tester, '35–44');
    await tapChip(tester, 'Casual');
    await tester.tap(find.text('Save changes'));
    await tester.pumpAndSettle();

    expect(find.text('We use it to tune how your lines sound.'), findsNothing);
    expect(find.text('Man'), findsOneWidget);
    expect(find.text('35–44'), findsOneWidget);
    expect(find.text('Casual'), findsOneWidget);
    final saved = profileManager.profile!;
    expect(saved.gender, Gender.man);
    expect(saved.ageRange, AgeRange.from35To44);
    expect(saved.goal, DatingGoal.casual);
  });

  testWidgets('a closed sheet changes nothing', (tester) async {
    await openProfile(tester);

    await tester.tap(find.text('Gender'));
    await tester.pumpAndSettle();
    await tapChip(tester, 'Non-binary');
    // Закрываем тапом по затемнению над шторкой.
    await tester.tapAt(const Offset(200, 100));
    await tester.pumpAndSettle();

    expect(find.text('Woman'), findsOneWidget);
    expect(profileManager.profile!.gender, Gender.woman);
  });

  testWidgets('the spice slider saves the level right away', (tester) async {
    await openProfile(tester);
    final slider = tester.getRect(find.byType(SpiceSlider));

    await tester.tapAt(slider.centerRight - const Offset(4, 0));
    await tester.pumpAndSettle();

    expect(find.text('Spicy'), findsNWidgets(2));
    expect(find.text('Daring, turns up the heat'), findsOneWidget);
    expect(profileManager.profile!.spice, SpiceLevel.spicy);

    // Бегунок тянут от правого края к середине.
    await tester.dragFrom(slider.centerRight - const Offset(4, 0), Offset(-slider.width / 2, 0));
    await tester.pumpAndSettle();

    expect(find.text('Playful'), findsOneWidget);
    expect(profileManager.profile!.spice, SpiceLevel.playful);
  });

  testWidgets('a trial subscription shows Cue Plus with its end', (tester) async {
    sessionManager
      ..isPlus = true
      ..subscription = Subscription(
        productId: 'weekly',
        expiresAt: DateTime(2026, 9, 23),
        isTrial: true,
        willRenew: true,
      );

    await openProfile(tester);

    expect(find.text('Cue Plus'), findsOneWidget);
    expect(find.text('Free trial'), findsOneWidget);
    expect(find.text(r'Ends Sep 23, then $7.99 per week'), findsOneWidget);
    expect(find.text('Manage subscription'), findsOneWidget);
    expect(find.text('Go unlimited'), findsNothing);
  });
}
