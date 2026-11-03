import 'package:dating_assistant/misc/assets.dart';
import 'package:dating_assistant/misc/custom_views/message_bubble.dart';
import 'package:dating_assistant/misc/custom_views/option_card.dart';
import 'package:dating_assistant/misc/custom_views/primary_button.dart';
import 'package:dating_assistant/misc/fonts.dart';
import 'package:dating_assistant/presentation/splash/onboarding/onboarding_content.dart';
import 'package:dating_assistant/presentation/splash/onboarding/onboarding_view_model.dart';
import 'package:dating_assistant/presentation/splash/onboarding/views/onboarding_step_layout.dart';
import 'package:flutter/widgets.dart';

class TryItStep extends StatelessWidget {
  const TryItStep({super.key, required this.viewModel});

  final OnboardingViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return OnboardingStepLayout(
      content: [
        const OnboardingTitle(eyebrow: 'Try it · sample chat', title: 'What would you reply?'),
        const SizedBox(height: 32),
        Row(
          children: [
            ClipOval(child: Image.asset(AppImages.nika, width: 40, height: 40)),
            const SizedBox(width: 12),
            const Text(OnboardingContent.sampleContact, style: Fonts.headline),
          ],
        ),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerLeft,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 320),
            child: const MessageBubble(text: OnboardingContent.sampleMessage),
          ),
        ),
        const SizedBox(height: 32),
        const Spacer(),
        for (final (index, answer) in OnboardingContent.tryItAnswers.indexed) ...[
          if (index > 0) const SizedBox(height: 8),
          OptionCard(
            emoji: answer.emoji,
            title: answer.text,
            isSelected: viewModel.tryItAnswer == answer,
            isCompact: true,
            onTap: () => viewModel.selectTryItAnswer(answer),
          ),
        ],
      ],
      buttons: [PrimaryButton(title: 'Continue', onPressed: viewModel.canContinue ? viewModel.next : null)],
    );
  }
}
