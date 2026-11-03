import 'package:dating_assistant/misc/appearance.dart';
import 'package:dating_assistant/misc/custom_views/pastel_card.dart';
import 'package:dating_assistant/misc/custom_views/primary_button.dart';
import 'package:dating_assistant/misc/extensions/profile_titles.dart';
import 'package:dating_assistant/misc/fonts.dart';
import 'package:dating_assistant/presentation/splash/onboarding/onboarding_content.dart';
import 'package:dating_assistant/presentation/splash/onboarding/onboarding_view_model.dart';
import 'package:dating_assistant/presentation/splash/onboarding/views/onboarding_step_layout.dart';
import 'package:flutter/widgets.dart';

class YourVoiceStep extends StatelessWidget {
  const YourVoiceStep({super.key, required this.viewModel});

  static const _faded = Color(0x99000000);

  final OnboardingViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final name = viewModel.name;
    final voice = viewModel.voice;
    return OnboardingStepLayout(
      content: [
        OnboardingTitle(
          eyebrow: 'Your voice',
          title: name == null ? 'That’s your voice' : 'That’s your voice, $name',
          subtitle: 'It gets sharper with every chat you analyze.',
        ),
        const SizedBox(height: 32),
        SizedBox(
          height: 380,
          child: PastelCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(spacing: 8, runSpacing: 8, children: [for (final trait in voice.traitTitles) _TraitPill(trait)]),
                const Spacer(),
                Text('Sounds like you', style: Fonts.eyebrow.copyWith(color: _faded)),
                const SizedBox(height: 8),
                Text(OnboardingContent.voicePreview.styled(voice), style: Fonts.phrase),
                const Spacer(),
                Row(
                  children: [
                    Text('Voice learned', style: Fonts.label.copyWith(color: _faded)),
                    const Spacer(),
                    Text(
                      '${(OnboardingContent.voiceLearned * 100).round()}%',
                      style: Fonts.label.copyWith(fontWeight: FontWeight.w600, color: Appearance.black),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  height: 6,
                  alignment: Alignment.centerLeft,
                  decoration: BoxDecoration(color: const Color(0x1A000000), borderRadius: BorderRadius.circular(3)),
                  child: FractionallySizedBox(
                    widthFactor: OnboardingContent.voiceLearned,
                    child: DecoratedBox(
                      decoration: BoxDecoration(color: Appearance.accent, borderRadius: BorderRadius.circular(3)),
                      child: const SizedBox.expand(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
      buttons: [PrimaryButton(title: 'Sounds like me', onPressed: viewModel.next)],
    );
  }
}

class _TraitPill extends StatelessWidget {
  const _TraitPill(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: const Color(0x1A000000), borderRadius: BorderRadius.circular(999)),
      child: Text(title, style: Fonts.label.copyWith(color: Appearance.black)),
    );
  }
}
