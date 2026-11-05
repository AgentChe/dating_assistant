import 'package:dating_assistant/misc/appearance.dart';
import 'package:dating_assistant/misc/assets.dart';
import 'package:dating_assistant/misc/custom_views/glass_button.dart';
import 'package:dating_assistant/misc/fonts.dart';
import 'package:flutter/widgets.dart';

/// Шапка главной: приветствие с оранжевой точкой, «What are we writing back?» и кнопка меню.
class HomeHeader extends StatelessWidget {
  const HomeHeader({super.key, required this.greeting, required this.onMenu});

  final String greeting;

  final VoidCallback onMenu;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Flexible(
                    child: Text(greeting, style: Fonts.title.copyWith(fontSize: 20, height: 25.2 / 20)),
                  ),
                  // Точка вместо точки в конце фразы — на уровне базовой линии.
                  Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.only(top: 13),
                    decoration: const BoxDecoration(shape: BoxShape.circle, gradient: Appearance.accentGradient),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text('What are we writing back?', style: Fonts.subtitle.copyWith(height: 20 / 16)),
            ],
          ),
        ),
        GlassButton(icon: AppIcons.menu, onPressed: onMenu, semanticLabel: 'Menu'),
      ],
    );
  }
}
