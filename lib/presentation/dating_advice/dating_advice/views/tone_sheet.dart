import 'package:dating_assistant/misc/appearance.dart';
import 'package:dating_assistant/misc/custom_views/app_bottom_sheet.dart';
import 'package:dating_assistant/misc/custom_views/pressable.dart';
import 'package:dating_assistant/misc/extensions/coach_titles.dart';
import 'package:dating_assistant/misc/fonts.dart';
import 'package:dating_assistant/service/coach/model/coach_tone.dart';
import 'package:flutter/widgets.dart';

/// Шторка «Select tone»: каким тоном коуч пишет готовые сообщения. Выбор сразу закрывает шторку.
class ToneSheet extends StatelessWidget {
  const ToneSheet({super.key, required this.selected});

  /// Завершается выбранным тоном или null, если шторку закрыли.
  static Future<CoachTone?> show(BuildContext context, {required CoachTone selected}) => AppBottomSheet.show<CoachTone>(
    context,
    // Шторка маленькая и открывается поверх чата — затемнение 20%, как в Figma.
    barrierColor: const Color(0x33000000),
    builder: (_) => ToneSheet(selected: selected),
  );

  final CoachTone selected;

  @override
  Widget build(BuildContext context) {
    return AppBottomSheet(
      children: [
        Text(
          'Select tone',
          textAlign: TextAlign.center,
          style: Fonts.headline.copyWith(fontSize: 22, height: 27.72 / 22),
        ),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (final tone in CoachTone.values)
              _ToneTab(tone: tone, isSelected: tone == selected, onTap: () => Navigator.pop(context, tone)),
          ],
        ),
      ],
    );
  }
}

/// Тон в шторке: выбранный — на пастельной пилюле, остальные — на тёмной.
class _ToneTab extends StatelessWidget {
  const _ToneTab({required this.tone, required this.isSelected, required this.onTap});

  final CoachTone tone;

  final bool isSelected;

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final style = Fonts.body.copyWith(
      fontSize: 18,
      height: 22.68 / 18,
      color: isSelected ? Appearance.black : Appearance.white,
    );
    return Semantics(
      selected: isSelected,
      child: Pressable(
        onTap: onTap,
        child: Container(
          height: 43,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: ShapeDecoration(
            shape: const StadiumBorder(),
            gradient: isSelected ? Appearance.pastelGradient : null,
            color: isSelected ? null : Appearance.surfaceRaised,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(tone.emoji, style: style),
              const SizedBox(width: 8),
              Text(tone.title, style: style),
            ],
          ),
        ),
      ),
    );
  }
}
