import 'dart:math' as math;

import 'package:dating_assistant/misc/fonts.dart';
import 'package:dating_assistant/presentation/splash/onboarding/views/onboarding_header.dart';
import 'package:flutter/widgets.dart';

/// Каркас шага онбординга: прокручиваемое содержимое и кнопки внизу.
///
/// [content] идёт сверху вниз; Spacer между ними забирает свободное место, поэтому то,
/// что после него, прижимается к кнопкам. На маленьком экране содержимое прокручивается.
class OnboardingStepLayout extends StatelessWidget {
  const OnboardingStepLayout({
    super.key,
    required this.content,
    required this.buttons,
    this.topInset = OnboardingHeader.height + 24,
    this.bottomInset = 40,
  });

  final List<Widget> content;

  final List<Widget> buttons;

  /// Отступ сверху; по умолчанию — под шапкой.
  final double topInset;

  /// Отступ от содержимого до кнопок.
  final double bottomInset;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(16, topInset, 16, bottomInset),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: math.max(0, constraints.maxHeight - topInset - bottomInset)),
                child: IntrinsicHeight(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: content),
                ),
              ),
            ),
          ),
        ),
        OnboardingFooter(buttons: buttons),
      ],
    );
  }
}

/// Кнопки внизу шага: над home indicator, а при открытой клавиатуре — над ней.
class OnboardingFooter extends StatelessWidget {
  const OnboardingFooter({super.key, required this.buttons});

  final List<Widget> buttons;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, math.max(MediaQuery.paddingOf(context).bottom + 3, 16)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (index, button) in buttons.indexed) ...[if (index > 0) const SizedBox(height: 8), button],
        ],
      ),
    );
  }
}

/// Надзаголовок, заголовок и подзаголовок шага.
class OnboardingTitle extends StatelessWidget {
  const OnboardingTitle({super.key, this.eyebrow, required this.title, this.subtitle});

  final String? eyebrow;

  final String title;

  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final eyebrow = this.eyebrow;
    final subtitle = this.subtitle;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (eyebrow != null) ...[Text(eyebrow, style: Fonts.eyebrow), const SizedBox(height: 12)],
        Text(title, style: Fonts.title),
        if (subtitle != null) ...[const SizedBox(height: 12), Text(subtitle, style: Fonts.subtitle)],
      ],
    );
  }
}

/// Пояснение с эмодзи слева — «почему так» под примером и на экране плана.
class OnboardingNote extends StatelessWidget {
  const OnboardingNote({super.key, required this.emoji, required this.text});

  final String emoji;

  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(emoji, style: const TextStyle(fontSize: 20, height: 1.2)),
        const SizedBox(width: 12),
        Expanded(child: Text(text, style: Fonts.caption)),
      ],
    );
  }
}
