import 'package:dating_assistant/misc/appearance.dart';
import 'package:dating_assistant/misc/assets.dart';
import 'package:dating_assistant/misc/custom_views/primary_button.dart';
import 'package:dating_assistant/misc/extensions/profile_titles.dart';
import 'package:dating_assistant/misc/fonts.dart';
import 'package:dating_assistant/presentation/splash/onboarding/onboarding_content.dart';
import 'package:dating_assistant/presentation/splash/onboarding/onboarding_view_model.dart';
import 'package:dating_assistant/presentation/splash/onboarding/views/onboarding_step_layout.dart';
import 'package:dating_assistant/service/profile/model/hardest_part.dart';
import 'package:flutter/widgets.dart';

/// «Made for you»: пояснения к выбранным трудностям. Свечение за иконкой рисует экран онбординга.
class InsightStep extends StatelessWidget {
  const InsightStep({super.key, required this.viewModel});

  final OnboardingViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return OnboardingStepLayout(
      bottomInset: 23,
      content: [
        const SizedBox(height: 30),
        Center(child: Image.asset(AppImages.chat3d, width: 176, height: 176)),
        const SizedBox(height: 46),
        const Spacer(),
        const OnboardingTitle(
          eyebrow: 'Made for you',
          title: 'You’re not bad at texting.\nYou’re just guessing.',
          subtitle: 'It’s almost never about you. Cue reads the chat, so you can stop guessing.',
        ),
        const SizedBox(height: 24),
        _PicksCard(parts: viewModel.hardestParts),
      ],
      buttons: [PrimaryButton(title: 'Continue', onPressed: viewModel.next)],
    );
  }
}

class _PicksCard extends StatelessWidget {
  const _PicksCard({required this.parts});

  final List<HardestPart> parts;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Appearance.surface, borderRadius: BorderRadius.circular(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('For what you picked', style: Fonts.eyebrow),
          for (final (index, part) in parts.indexed) ...[
            if (index > 0) ...[
              const SizedBox(height: 16),
              Container(height: 1, color: const Color(0x0DFFFFFF)),
            ],
            const SizedBox(height: 16),
            _PickRow(part: part),
          ],
        ],
      ),
    );
  }
}

class _PickRow extends StatelessWidget {
  const _PickRow({required this.part});

  final HardestPart part;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          decoration: const BoxDecoration(shape: BoxShape.circle, color: Appearance.surfaceRaised),
          child: Text(part.emoji, style: const TextStyle(fontSize: 20, height: 1.25)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(OnboardingContent.insightTitle(part), style: Fonts.headline),
              const SizedBox(height: 2),
              Text(OnboardingContent.insightText(part), style: Fonts.caption),
            ],
          ),
        ),
      ],
    );
  }
}
