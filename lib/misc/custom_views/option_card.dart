import 'package:dating_assistant/misc/appearance.dart';
import 'package:dating_assistant/misc/assets.dart';
import 'package:dating_assistant/misc/custom_views/pressable.dart';
import 'package:dating_assistant/misc/custom_views/svg_icon.dart';
import 'package:dating_assistant/misc/fonts.dart';
import 'package:flutter/widgets.dart';

/// Вариант ответа из Figma (card/option): эмодзи, заголовок и подзаголовок; выбранный — белый.
class OptionCard extends StatelessWidget {
  const OptionCard({
    super.key,
    required this.emoji,
    required this.title,
    this.subtitle,
    required this.isSelected,
    required this.onTap,
    this.isMultiSelect = false,
    this.isCompact = false,
  });

  final String emoji;

  final String title;

  final String? subtitle;

  final bool isSelected;

  final VoidCallback onTap;

  /// Кружок с галочкой справа — когда можно выбрать несколько вариантов.
  final bool isMultiSelect;

  /// Высота 52 вместо 72 — для коротких однострочных вариантов.
  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    final subtitle = this.subtitle;
    return Pressable(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        constraints: BoxConstraints(minHeight: isCompact ? 52 : 72),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? Appearance.white : Appearance.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isSelected ? Appearance.white : Appearance.hairline),
        ),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 24, height: 1.25)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(title, style: Fonts.headline.copyWith(color: isSelected ? Appearance.black : Appearance.white)),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: Fonts.caption.copyWith(color: isSelected ? const Color(0x99000000) : Appearance.grey),
                    ),
                  ],
                ],
              ),
            ),
            if (isMultiSelect) ...[const SizedBox(width: 12), _Checkmark(isSelected: isSelected)],
          ],
        ),
      ),
    );
  }
}

class _Checkmark extends StatelessWidget {
  const _Checkmark({required this.isSelected});

  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isSelected ? Appearance.black : null,
        border: isSelected ? null : Border.all(color: const Color(0x3DFFFFFF), width: 1.5),
      ),
      child: isSelected ? const Center(child: SvgIcon(AppIcons.check, size: 16, color: Appearance.white)) : null,
    );
  }
}
