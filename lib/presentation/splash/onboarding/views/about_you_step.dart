import 'package:dating_assistant/misc/custom_views/pill_chip.dart';
import 'package:dating_assistant/misc/custom_views/primary_button.dart';
import 'package:dating_assistant/misc/extensions/profile_titles.dart';
import 'package:dating_assistant/misc/fonts.dart';
import 'package:dating_assistant/presentation/splash/onboarding/onboarding_view_model.dart';
import 'package:dating_assistant/presentation/splash/onboarding/views/onboarding_step_layout.dart';
import 'package:dating_assistant/service/profile/model/age_range.dart';
import 'package:dating_assistant/service/profile/model/gender.dart';
import 'package:flutter/widgets.dart';

class AboutYouStep extends StatelessWidget {
  const AboutYouStep({super.key, required this.viewModel});

  final OnboardingViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return OnboardingStepLayout(
      content: [
        const OnboardingTitle(
          eyebrow: 'About you',
          title: 'A bit more about you',
          subtitle: 'Age and gender change how a line lands. We tune for both.',
        ),
        const SizedBox(height: 32),
        _ChipGroup(
          title: 'Gender',
          reason: 'Your voice reads differently depending on it',
          chips: [
            for (final gender in Gender.values)
              PillChip(
                label: gender.title,
                isSelected: viewModel.gender == gender,
                onTap: () => viewModel.selectGender(gender),
              ),
          ],
        ),
        const SizedBox(height: 28),
        _ChipGroup(
          title: 'Age',
          reason: 'Twenty-five and forty-five don’t text the same',
          chips: [
            for (final ageRange in AgeRange.values)
              PillChip(
                label: ageRange.title,
                isSelected: viewModel.ageRange == ageRange,
                onTap: () => viewModel.selectAgeRange(ageRange),
              ),
          ],
        ),
      ],
      buttons: [PrimaryButton(title: 'Continue', onPressed: viewModel.canContinue ? viewModel.next : null)],
    );
  }
}

class _ChipGroup extends StatelessWidget {
  const _ChipGroup({required this.title, required this.reason, required this.chips});

  final String title;

  final String reason;

  final List<Widget> chips;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Fonts.headline.copyWith(height: 20 / 16)),
        const SizedBox(height: 4),
        Text(reason, style: Fonts.caption.copyWith(height: 18 / 14)),
        const SizedBox(height: 12),
        Wrap(spacing: 8, runSpacing: 8, children: chips),
      ],
    );
  }
}
