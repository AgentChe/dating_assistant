import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' show ImageFilter;

import 'package:dating_assistant/misc/appearance.dart';
import 'package:flutter/widgets.dart';

/// Скриншот, который «сканируется»: над линией он чёткий, под ней — размыт и подсвечен оранжевым.
class ScanningScreenshot extends StatelessWidget {
  const ScanningScreenshot({super.key, required this.screenshot, required this.progress});

  /// Пропорции рамки из Figma: 290×566.
  static const _aspectRatio = 290 / 566;

  /// На сколько линия и размытие выходят за края скриншота.
  static const _overhang = 27.0;

  final Uint8List screenshot;

  /// От 0 до 1: где сейчас линия.
  final double progress;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = math.min(
          math.min(290.0, constraints.maxWidth - 2 * _overhang),
          constraints.maxHeight * _aspectRatio,
        );
        final height = width / _aspectRatio;
        final line = height * progress.clamp(0, 1);

        return SizedBox(
          width: width,
          height: height,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(32),
                  child: Image.memory(screenshot, fit: BoxFit.cover, gaplessPlayback: true),
                ),
              ),
              // Ещё не просканировано: размытие чуть шире скриншота, чтобы края расплывались наружу.
              Positioned(
                left: 1 - _overhang,
                right: 1 - _overhang,
                top: line,
                bottom: 0,
                child: ClipRect(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                    child: const SizedBox.expand(),
                  ),
                ),
              ),
              // Оранжевое свечение от линии вниз, на 15 шире скриншота с каждой стороны и с мягкими краями.
              Positioned(
                left: -15,
                right: -15,
                top: line,
                bottom: 0,
                child: ImageFiltered(
                  imageFilter: ImageFilter.blur(sigmaX: 4, sigmaY: 4, tileMode: TileMode.decal),
                  child: const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0x80FF845E), Color(0x00FF845E)],
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: -_overhang,
                right: -_overhang,
                top: line - 2.5,
                height: 5,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [Appearance.accent, Color(0xFFFF997B)],
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
