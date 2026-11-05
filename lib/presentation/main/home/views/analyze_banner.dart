import 'package:dating_assistant/misc/appearance.dart';
import 'package:dating_assistant/misc/assets.dart';
import 'package:dating_assistant/misc/custom_views/primary_button.dart';
import 'package:dating_assistant/misc/fonts.dart';
import 'package:flutter/widgets.dart';

/// Пастельный баннер «Analyze your chat»: анкета и чат со «сканированием», 3D-иконка чата и «Upload screenshot».
class AnalyzeBanner extends StatelessWidget {
  const AnalyzeBanner({super.key, required this.onUpload});

  final VoidCallback onUpload;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 380,
      decoration: BoxDecoration(gradient: Appearance.pastelGradient, borderRadius: BorderRadius.circular(24)),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          const Positioned(left: 0, right: 0, top: 65, height: 231, child: _Illustration()),
          Positioned(
            left: 16,
            top: 16,
            right: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Analyze your chat',
                  style: Fonts.headline.copyWith(fontSize: 18, height: 22.7 / 18, color: Appearance.black),
                ),
                const SizedBox(height: 4),
                Text(
                  'See where things really stand,\nthen get the next message',
                  style: Fonts.subtitle.copyWith(height: 20 / 16),
                ),
              ],
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: PrimaryButton.dark(title: 'Upload screenshot', onPressed: onUpload),
          ),
          // Иконка выходит за правый верхний угол баннера, как в Figma.
          Positioned(top: -12, right: -13, width: 100, height: 100, child: Image.asset(AppImages.chat3d)),
        ],
      ),
    );
  }
}

/// Анкета и чат с кругами за ними — композиция 396×231 из Figma; на узком экране уменьшается целиком.
class _Illustration extends StatelessWidget {
  const _Illustration();

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: SizedBox(
        width: 396,
        height: 231,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            _circle(left: 17, top: 0, size: 171, color: const Color(0x40FFFFFF)),
            _circle(left: 32, top: 16, size: 140.5, color: const Color(0x59FFFFFF)),
            // Картинки выгружены из Figma вместе с наклоном карточек и размытием под линией сканирования.
            Positioned(
              left: 57,
              top: 32,
              width: 155.7,
              height: 186.7,
              child: Image.asset(AppImages.analyzeProfileCard),
            ),
            Positioned(
              left: 191,
              top: 28,
              width: 176,
              height: 202.3,
              child: Image.asset(AppImages.analyzeChatCard),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _circle({required double left, required double top, required double size, required Color color}) =>
      Positioned(
        left: left,
        top: top,
        width: size,
        height: size,
        child: DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 0.5),
          ),
        ),
      );
}
