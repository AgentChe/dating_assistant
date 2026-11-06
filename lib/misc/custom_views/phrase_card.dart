import 'package:dating_assistant/misc/appearance.dart';
import 'package:dating_assistant/misc/assets.dart';
import 'package:dating_assistant/misc/custom_views/pastel_card.dart';
import 'package:dating_assistant/misc/custom_views/pressable.dart';
import 'package:dating_assistant/misc/custom_views/svg_icon.dart';
import 'package:dating_assistant/misc/fonts.dart';
import 'package:flutter/cupertino.dart';

/// Готовая фраза из Figma (card/phrase): пастельная карточка, кнопка «скопировать» и подпись снизу.
class PhraseCard extends StatelessWidget {
  const PhraseCard({
    super.key,
    required this.text,
    required this.caption,
    required this.onCopy,
    this.isCopied = false,
    this.isLoading = false,
  });

  /// null — фразы ещё нет, вместо неё спиннер.
  final String? text;

  final String caption;

  /// null — копировать нечего.
  final VoidCallback? onCopy;

  /// Только что скопировали — вместо иконки копирования галочка.
  final bool isCopied;

  /// Пишется новая фраза — старая приглушена.
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final text = this.text;
    return PastelCard(
      radius: 20,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: text == null
                      ? const Align(
                          alignment: Alignment.centerLeft,
                          child: SizedBox(
                            height: 46,
                            child: CupertinoActivityIndicator(color: Appearance.black),
                          ),
                        )
                      : AnimatedOpacity(
                          key: ValueKey(text),
                          opacity: isLoading ? 0.4 : 1,
                          duration: const Duration(milliseconds: 200),
                          child: Text(
                            text,
                            style: Fonts.body.copyWith(fontSize: 18, height: 23 / 18, color: Appearance.black),
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 20),
              Pressable(
                onTap: text == null || isLoading ? null : onCopy,
                semanticLabel: 'Copy',
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 150),
                  child: SvgIcon(
                    isCopied ? AppIcons.check : AppIcons.copy,
                    key: ValueKey(isCopied),
                    color: Appearance.black,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(caption, style: Fonts.eyebrow.copyWith(fontWeight: FontWeight.w300)),
        ],
      ),
    );
  }
}
