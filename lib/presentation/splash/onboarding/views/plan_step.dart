import 'package:dating_assistant/misc/appearance.dart';
import 'package:dating_assistant/misc/custom_views/pastel_card.dart';
import 'package:dating_assistant/misc/custom_views/primary_button.dart';
import 'package:dating_assistant/misc/extensions/profile_titles.dart';
import 'package:dating_assistant/misc/fonts.dart';
import 'package:dating_assistant/presentation/splash/onboarding/onboarding_content.dart';
import 'package:dating_assistant/presentation/splash/onboarding/onboarding_view_model.dart';
import 'package:dating_assistant/presentation/splash/onboarding/views/onboarding_step_layout.dart';
import 'package:dating_assistant/service/profile/model/spice_level.dart';
import 'package:flutter/widgets.dart';

/// «Your Cue is ready»: итог ответов и с чего начать.
class PlanStep extends StatelessWidget {
  const PlanStep({super.key, required this.viewModel});

  final OnboardingViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final name = viewModel.name;
    final spice = viewModel.spice;
    final startingPoint = viewModel.startingPoint;
    return OnboardingStepLayout(
      topInset: 48,
      content: [
        OnboardingTitle(
          eyebrow: 'All set',
          title: name == null ? 'Your Cue is ready' : '$name, your Cue is ready',
          subtitle: 'Built from your answers. Change anything in Profile.',
        ),
        const SizedBox(height: 28),
        PastelCard(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Column(
            children: [
              for (final (index, row) in [
                ('🎯', 'Looking for', viewModel.goal?.title ?? ''),
                ('🌶️', 'Starting spice', '${spice.title} · ${spice.level} of ${SpiceLevel.values.length}'),
                ('🗣️', 'Your voice', viewModel.voice.summary),
                ('💬', 'Your chats', 'Screenshots from any app, WhatsApp and Telegram exports'),
                ('📍', 'Start with', OnboardingContent.startingTitle(startingPoint)),
              ].indexed) ...[
                if (index > 0) Container(height: 1, color: const Color(0x80FFFFFF)),
                _PlanRow(emoji: row.$1, label: row.$2, value: row.$3),
              ],
            ],
          ),
        ),
        const SizedBox(height: 20),
        OnboardingNote(emoji: '💡', text: OnboardingContent.startingTip(viewModel.mainHardestPart)),
      ],
      buttons: [
        PrimaryButton(title: OnboardingContent.startingAction(startingPoint), onPressed: viewModel.next),
        PrimaryButton.plain(title: 'I’ll look around first', onPressed: viewModel.next),
      ],
    );
  }
}

class _PlanRow extends StatelessWidget {
  const _PlanRow({required this.emoji, required this.label, required this.value});

  final String emoji;

  final String label;

  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 20, height: 1.25)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: Fonts.eyebrow.copyWith(color: const Color(0x99000000))),
                const SizedBox(height: 2),
                Text(value, style: Fonts.headline.copyWith(color: Appearance.black)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
