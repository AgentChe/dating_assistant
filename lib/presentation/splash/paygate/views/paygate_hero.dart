import 'package:dating_assistant/misc/assets.dart';
import 'package:flutter/widgets.dart';

/// 3D-иконки со свечением — композиция 396×194 из Figma; на узких экранах уменьшается целиком.
class PaygateHero extends StatelessWidget {
  const PaygateHero({super.key});

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: SizedBox(
        width: 396,
        height: 194,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: -2,
              top: -103,
              width: 400,
              height: 400,
              child: IgnorePointer(child: Opacity(opacity: 0.2, child: Image.asset(AppImages.glow))),
            ),
            _icon(AppImages.quotes3d, left: 38, top: -5, size: 95),
            _icon(AppImages.bars3d, left: 58, top: 105, size: 77),
            _icon(AppImages.chat3d, left: 128, top: 24, size: 140),
            _icon(AppImages.question3d, left: 265, top: 92, size: 100),
            _icon(AppImages.sparkle3d, left: 308, top: 8, size: 52),
          ],
        ),
      ),
    );
  }

  static Widget _icon(String asset, {required double left, required double top, required double size}) {
    return Positioned(
      left: left,
      top: top,
      child: Image.asset(asset, width: size, height: size),
    );
  }
}
