import 'package:dating_assistant/misc/appearance.dart';
import 'package:dating_assistant/misc/custom_views/pressable.dart';
import 'package:dating_assistant/misc/custom_views/screen_header.dart';
import 'package:dating_assistant/misc/fonts.dart';
import 'package:flutter/widgets.dart';

/// Пустая история (History empty из Figma): что здесь будет и «Analyze a chat».
class HistoryEmpty extends StatelessWidget {
  const HistoryEmpty({super.key, required this.onAnalyze});

  final VoidCallback onAnalyze;

  @override
  Widget build(BuildContext context) {
    return Padding(
      // Текст в макете шириной 364: так строки переносятся, как там.
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Your conversations land here', textAlign: TextAlign.center, style: ScreenHeader.titleStyle),
          const SizedBox(height: 12),
          const Text(
            'Every chat you break down and every coach session is saved here, so you can pick up '
            'without starting over.',
            textAlign: TextAlign.center,
            style: Fonts.subtitle,
          ),
          const SizedBox(height: 24),
          Pressable(
            onTap: onAnalyze,
            child: Container(
              height: 52,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              decoration: const ShapeDecoration(shape: StadiumBorder(), gradient: Appearance.pastelGradient),
              child: const Center(widthFactor: 1, child: Text('Analyze a chat', style: Fonts.button)),
            ),
          ),
        ],
      ),
    );
  }
}
