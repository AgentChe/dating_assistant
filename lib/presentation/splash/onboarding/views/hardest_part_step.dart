import 'package:dating_assistant/misc/custom_views/option_card.dart';
import 'package:dating_assistant/misc/custom_views/primary_button.dart';
import 'package:dating_assistant/misc/extensions/profile_titles.dart';
import 'package:dating_assistant/presentation/splash/onboarding/onboarding_view_model.dart';
import 'package:dating_assistant/presentation/splash/onboarding/views/onboarding_step_layout.dart';
import 'package:dating_assistant/service/profile/model/hardest_part.dart';
import 'package:flutter/widgets.dart';

class HardestPartStep extends StatelessWidget {
  const HardestPartStep({super.key, required this.viewModel});

  final OnboardingViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final selected = viewModel.hardestParts;
    return OnboardingStepLayout(
      content: [
        const OnboardingTitle(
          eyebrow: 'About you',
          title: 'What’s the hardest part for you?',
          subtitle: 'Pick all that apply — that’s where we’ll start.',
        ),
        const SizedBox(height: 32),
        const Spacer(),
        for (final part in HardestPart.values) ...[
          if (part.index > 0) const SizedBox(height: 8),
          OptionCard(
            emoji: part.emoji,
            title: part.title,
            isSelected: selected.contains(part),
            isMultiSelect: true,
            onTap: () => viewModel.toggleHardestPart(part),
          ),
        ],
      ],
      buttons: [PrimaryButton(title: 'Continue', onPressed: viewModel.canContinue ? viewModel.next : null)],
    );
  }
}
