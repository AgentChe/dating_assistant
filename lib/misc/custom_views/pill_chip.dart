import 'package:dating_assistant/misc/appearance.dart';
import 'package:dating_assistant/misc/custom_views/pressable.dart';
import 'package:dating_assistant/misc/fonts.dart';
import 'package:flutter/widgets.dart';

/// Чип-пилюля из Figma (chip): выбранный — белый с чёрным текстом.
class PillChip extends StatelessWidget {
  const PillChip({super.key, required this.label, required this.isSelected, required this.onTap});

  final String label;

  final bool isSelected;

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: isSelected ? Appearance.white : Appearance.surface,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: isSelected ? Appearance.white : Appearance.hairline),
        ),
        child: Center(
          widthFactor: 1,
          child: Text(label, style: Fonts.label.copyWith(color: isSelected ? Appearance.black : Appearance.white)),
        ),
      ),
    );
  }
}
