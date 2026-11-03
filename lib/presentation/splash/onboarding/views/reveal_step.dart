import 'package:dating_assistant/misc/appearance.dart';
import 'package:dating_assistant/misc/assets.dart';
import 'package:dating_assistant/misc/custom_views/message_bubble.dart';
import 'package:dating_assistant/misc/custom_views/pastel_card.dart';
import 'package:dating_assistant/misc/custom_views/pressable.dart';
import 'package:dating_assistant/misc/custom_views/primary_button.dart';
import 'package:dating_assistant/misc/custom_views/svg_icon.dart';
import 'package:dating_assistant/misc/fonts.dart';
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
        _PhraseCard(text: OnboardingContent.cueReply.styled(viewModel.voice)),
        if (feedback != null) ...[const SizedBox(height: 16), OnboardingNote(emoji: '👀', text: feedback)],
        const Spacer(),
      ],
      buttons: [PrimaryButton(title: 'Continue', onPressed: viewModel.next)],
    );
  }
}

class _PhraseCard extends StatelessWidget {
  const _PhraseCard({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return PastelCard(
      radius: 20,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  text,
                  style: Fonts.body.copyWith(fontSize: 18, height: 23 / 18, color: Appearance.black),
                ),
              ),
              const SizedBox(width: 20),
              Pressable(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: text));
                  HapticFeedback.selectionClick();
                },
                semanticLabel: 'Copy',
                child: const SvgIcon(AppIcons.copy, color: Appearance.black),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text('Written in your voice', style: Fonts.eyebrow.copyWith(fontWeight: FontWeight.w300)),
        ],
      ),
    );
  }
}
