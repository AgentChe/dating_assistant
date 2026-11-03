import 'package:dating_assistant/misc/custom_views/option_card.dart';
import 'package:dating_assistant/misc/custom_views/primary_button.dart';
import 'package:dating_assistant/misc/extensions/profile_titles.dart';
import 'package:dating_assistant/presentation/splash/onboarding/onboarding_view_model.dart';
import 'package:dating_assistant/presentation/splash/onboarding/views/onboarding_step_layout.dart';
import 'package:dating_assistant/service/profile/model/dating_goal.dart';
import 'package:flutter/widgets.dart';

class GoalStep extends StatelessWidget {
  const GoalStep({super.key, required this.viewModel});

  final OnboardingViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final name = viewModel.name;
    return OnboardingStepLayout(
      content: [
        OnboardingTitle(
          eyebrow: 'About you',
          title: '${name == null ? 'Nice to meet you' : 'Nice to meet you, $name'} 👋\nWhat are you looking for?',
          subtitle: 'You can change it anytime.',
        ),
        const SizedBox(height: 32),
        const Spacer(),
        for (final goal in DatingGoal.values) ...[
          if (goal.index > 0) const SizedBox(height: 8),
          OptionCard(
            emoji: goal.emoji,
            title: goal.title,
            subtitle: goal.subtitle,
            isSelected: viewModel.goal == goal,
            onTap: () => viewModel.selectGoal(goal),
          ),
        ],
      ],
      buttons: [PrimaryButton(title: 'Continue', onPressed: viewModel.canContinue ? viewModel.next : null)],
    );
  }
}
