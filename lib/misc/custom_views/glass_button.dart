import 'package:dating_assistant/misc/appearance.dart';
import 'package:dating_assistant/misc/custom_views/pressable.dart';
import 'package:dating_assistant/misc/custom_views/svg_icon.dart';
import 'package:flutter/widgets.dart';

/// Круглая «стеклянная» кнопка из Figma (button/icon, 48×48): тёмный круг со светлым ободком.
class GlassButton extends StatelessWidget {
  const GlassButton({super.key, required this.icon, required this.onPressed, required this.semanticLabel});

  final String icon;

  final VoidCallback? onPressed;

  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onPressed,
      semanticLabel: semanticLabel,
      child: Container(
        width: 48,
        height: 48,
        padding: const EdgeInsets.all(1),
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          // Блик по краю, как у эффекта Glass в Figma.
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0x40FFFFFF), Color(0x0AFFFFFF), Color(0x26FFFFFF)],
          ),
        ),
        child: DecoratedBox(
          decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF161616)),
          child: Center(child: SvgIcon(icon, size: 20, color: Appearance.white)),
        ),
      ),
    );
  }
}
