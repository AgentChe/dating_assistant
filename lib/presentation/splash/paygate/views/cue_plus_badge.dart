import 'package:dating_assistant/misc/appearance.dart';
import 'package:dating_assistant/misc/assets.dart';
import 'package:dating_assistant/misc/fonts.dart';
import 'package:flutter/widgets.dart';

/// Плашка «Cue Plus» с иконкой приложения.
class CuePlusBadge extends StatelessWidget {
  const CuePlusBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(gradient: Appearance.pastelGradient, borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(5, 5, 12, 5),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(AppImages.splashIcon, width: 32, height: 32),
            ),
            const SizedBox(width: 6),
            Text(
              'Cue Plus',
              style: Fonts.eyebrow.copyWith(fontWeight: FontWeight.w600, color: Appearance.black),
            ),
          ],
        ),
      ),
    );
  }
}
