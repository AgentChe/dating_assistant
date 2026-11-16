import 'package:dating_assistant/misc/appearance.dart';
import 'package:dating_assistant/misc/assets.dart';
import 'package:dating_assistant/misc/fonts.dart';
import 'package:flutter/widgets.dart';

/// «How it works» — что уходит ИИ, кто его разбирает и что потом удаляется. Одна карточка на экране согласия
/// и в «AI & privacy».
///
/// Тексты поправлены против макета: в Figma «Analyzed by OpenAI», а переписки разбирает Google Gemini;
/// импорта переписки файлом в приложении нет, поэтому «chat files» и «files» убраны.
class PrivacyFacts extends StatelessWidget {
  const PrivacyFacts({super.key});

  static const _facts = [
    (AppImages.consentShared3d, 'Only what you share', 'Screenshots, coach messages and your answers.'),
    (
      AppImages.consentProvider3d,
      'Analyzed by Google Gemini',
      'Our AI provider. It doesn’t train its models on your chats.',
    ),
    (
      AppImages.consentDeleted3d,
      'Deleted after the breakdown',
      'Screenshots are gone right away. Your results stay in History.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Appearance.surface, borderRadius: BorderRadius.circular(20)),
      child: Column(
        children: [
          for (final (index, (icon, title, subtitle)) in _facts.indexed) ...[
            if (index > 0) ...[
              const SizedBox(height: 16),
              Container(height: 1, color: const Color(0x14FFFFFF)),
              const SizedBox(height: 16),
            ],
            MergeSemantics(
              child: Row(
                children: [
                  ExcludeSemantics(child: Image.asset(icon, width: 40, height: 40)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: Fonts.headline),
                        const SizedBox(height: 2),
                        Text(subtitle, style: Fonts.caption),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
