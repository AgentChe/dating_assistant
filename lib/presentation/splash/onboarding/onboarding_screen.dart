import 'dart:async';

import 'package:dating_assistant/misc/custom_views/try_again_sheet.dart';
import 'package:dating_assistant/misc/extensions/profile_titles.dart';
import 'package:dating_assistant/presentation/main/main/main_screen.dart';
import 'package:dating_assistant/presentation/splash/onboarding/onboarding_view_model.dart';
import 'package:dating_assistant/service/profile/model/dating_goal.dart';
import 'package:dating_assistant/service/profile/model/gender.dart';
import 'package:flutter/material.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  static Route<void> route() => MaterialPageRoute(builder: (_) => const OnboardingScreen());

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _viewModel = OnboardingViewModel();

  late final StreamSubscription<OnboardingAction> _actions;

  @override
  void initState() {
    super.initState();
    _viewModel.tryAgain = (error) => TryAgainSheet.show(context, error);
    _actions = _viewModel.actions.listen(_handle);
  }

  @override
  void dispose() {
    _actions.cancel();
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    // Временная вёрстка: экран соберём по макету из Figma.
    return Scaffold(
      appBar: AppBar(title: const Text('About you')),
      body: ListenableBuilder(
        listenable: _viewModel,
        builder: (context, _) => ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text('Gender', style: textTheme.titleMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                for (final gender in Gender.values)
                  ChoiceChip(
                    label: Text(gender.title),
                    selected: _viewModel.gender == gender,
                    onSelected: (_) => _viewModel.selectGender(gender),
                  ),
              ],
            ),
            const SizedBox(height: 24),
            Text('Age: ${_viewModel.age}', style: textTheme.titleMedium),
            Slider(
              value: _viewModel.age.toDouble(),
              min: OnboardingViewModel.minAge.toDouble(),
              max: OnboardingViewModel.maxAge.toDouble(),
              divisions: OnboardingViewModel.maxAge - OnboardingViewModel.minAge,
              onChanged: (value) => _viewModel.selectAge(value.round()),
            ),
            const SizedBox(height: 24),
            Text('Dating goal', style: textTheme.titleMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final datingGoal in DatingGoal.values)
                  ChoiceChip(
                    label: Text(datingGoal.title),
                    selected: _viewModel.datingGoal == datingGoal,
                    onSelected: (_) => _viewModel.selectDatingGoal(datingGoal),
                  ),
              ],
            ),
            const SizedBox(height: 32),
            FilledButton(
              onPressed: _viewModel.canFinish ? _viewModel.finish : null,
              child: _viewModel.isLoading
                  ? const SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Continue'),
            ),
          ],
        ),
      ),
    );
  }

  void _handle(OnboardingAction action) {
    switch (action) {
      case OnboardingAction.finished:
        Navigator.of(context).pushAndRemoveUntil(MainScreen.route(), (_) => false);
    }
  }
}
