import 'package:dating_assistant/misc/appearance.dart';
import 'package:dating_assistant/misc/assets.dart';
import 'package:dating_assistant/misc/custom_views/pastel_card.dart';
import 'package:dating_assistant/misc/custom_views/pressable.dart';
import 'package:dating_assistant/misc/custom_views/svg_icon.dart';
import 'package:dating_assistant/misc/fonts.dart';
import 'package:dating_assistant/service/coach/model/coach_reply.dart';
import 'package:flutter/widgets.dart';

/// Готовое сообщение от коуча (suggest-card из Figma): «Try sending», текст и почему он сработает.
/// Нажатие на карточку копирует сообщение — на пару секунд вместо иконки копирования галочка.
class SuggestionCard extends StatelessWidget {
  const SuggestionCard({super.key, required this.suggestion, required this.isCopied, required this.onCopy});

  /// Подписи — чёрный 60%.
  static const _secondary = Color(0x99000000);

  final CoachSuggestion suggestion;

  final bool isCopied;

  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    final why = suggestion.why;
    // Отдельный узел для VoiceOver: иначе совет коуча над карточкой читается как часть кнопки «Copy».
    return Semantics(
      container: true,
      child: Pressable(
        onTap: onCopy,
        semanticLabel: 'Copy',
        child: PastelCard(
          radius: 16,
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Try sending', style: Fonts.eyebrow.copyWith(color: _secondary)),
                        const SizedBox(height: 4),
                        Text(suggestion.text, style: Fonts.body.copyWith(color: Appearance.black)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 150),
                    child: SvgIcon(
                      isCopied ? AppIcons.check : AppIcons.copy,
                      key: ValueKey(isCopied),
                      color: Appearance.black,
                    ),
                  ),
                ],
              ),
              if (why != null) ...[
                const SizedBox(height: 8),
                Text(
                  why,
                  style: Fonts.eyebrow.copyWith(fontWeight: FontWeight.w400, height: 16 / 12, color: _secondary),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
