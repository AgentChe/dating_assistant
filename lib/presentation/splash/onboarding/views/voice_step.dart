import 'package:dating_assistant/presentation/splash/onboarding/onboarding_content.dart';
import 'package:dating_assistant/presentation/splash/onboarding/views/onboarding_header.dart';
import 'package:dating_assistant/presentation/splash/onboarding/views/onboarding_step_layout.dart';
import 'package:dating_assistant/presentation/splash/onboarding/views/voice_deck.dart';
import 'package:flutter/widgets.dart';

/// Калибровка голоса: три карточки подряд, без кнопки «Continue».
class VoiceStep extends StatelessWidget {
  const VoiceStep({super.key, required this.index, required this.onAnswer});

  /// Номер карточки берём при создании: уходящий шаг не должен читать индекс,
  /// который уже перешагнул за последнюю карточку.
  final int index;

  final void Function({required bool isMe}) onAnswer;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, OnboardingHeader.height + 24, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          OnboardingTitle(
            eyebrow: 'Your voice · ${index + 1} of ${OnboardingContent.voiceSamples.length}',
            title: 'Would you send this?',
            subtitle: 'Swipe right if it sounds like you.',
          ),
          const SizedBox(height: 32),
          VoiceDeck(index: index, onAnswer: onAnswer),
        ],
      ),
    );
  }
}
