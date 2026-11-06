import 'package:dating_assistant/misc/assets.dart';
import 'package:dating_assistant/misc/custom_views/message_bubble.dart';
import 'package:dating_assistant/misc/custom_views/phrase_card.dart';
import 'package:dating_assistant/misc/custom_views/primary_button.dart';
import 'package:dating_assistant/presentation/splash/onboarding/onboarding_content.dart';
import 'package:dating_assistant/presentation/splash/onboarding/onboarding_view_model.dart';
import 'package:dating_assistant/presentation/splash/onboarding/views/onboarding_step_layout.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// «Here’s the Cue version»: ответ Cue голосом пользователя и чем он лучше выбранного.
class RevealStep extends StatelessWidget {
  const RevealStep({super.key, required this.viewModel});

  final OnboardingViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final feedback = viewModel.tryItAnswer?.feedback;
    return OnboardingStepLayout(
      content: [
        const OnboardingTitle(eyebrow: 'Try it · sample chat', title: 'Here’s the Cue version'),
        const SizedBox(height: 32),
        const Spacer(),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            ClipOval(child: Image.asset(AppImages.nika, width: 32, height: 32)),
            const SizedBox(width: 8),
            Flexible(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 300),
                child: const MessageBubble(text: OnboardingContent.sampleMessage),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        PhraseCard(
          text: OnboardingContent.cueReply.styled(viewModel.voice),
          caption: 'Written in your voice',
          onCopy: () {
            Clipboard.setData(ClipboardData(text: OnboardingContent.cueReply.styled(viewModel.voice)));
            HapticFeedback.selectionClick();
          },
        ),
        if (feedback != null) ...[const SizedBox(height: 16), OnboardingNote(emoji: '👀', text: feedback)],
        const Spacer(),
      ],
      buttons: [PrimaryButton(title: 'Continue', onPressed: viewModel.next)],
    );
  }
}
