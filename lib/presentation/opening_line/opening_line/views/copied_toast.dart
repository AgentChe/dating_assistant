import 'package:dating_assistant/misc/appearance.dart';
import 'package:dating_assistant/misc/assets.dart';
import 'package:dating_assistant/misc/custom_views/glass_panel.dart';
import 'package:dating_assistant/misc/custom_views/svg_icon.dart';
import 'package:dating_assistant/misc/fonts.dart';
import 'package:flutter/widgets.dart';

/// Стеклянная плашка «Copied — paste it into your chat» с оранжевой галочкой.
class CopiedToast extends StatelessWidget {
  const CopiedToast({super.key});

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      borderRadius: BorderRadius.circular(24),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 10, 18, 10),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 28,
              height: 28,
              alignment: Alignment.center,
              decoration: const BoxDecoration(shape: BoxShape.circle, color: Appearance.accent),
              child: const SvgIcon(AppIcons.check, size: 16, color: Appearance.black),
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Text('Copied — paste it into your chat', style: Fonts.label.copyWith(height: 17.6 / 14)),
            ),
          ],
        ),
      ),
    );
  }
}
