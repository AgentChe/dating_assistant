import 'dart:math' as math;

import 'package:dating_assistant/misc/appearance.dart';
import 'package:dating_assistant/misc/custom_views/glass_panel.dart';
import 'package:dating_assistant/misc/fonts.dart';
import 'package:flutter/widgets.dart';

/// Стеклянная капсула внизу, на месте таб-бара: «10% Scanning» и бегущая точка.
class ScanningProgress extends StatefulWidget {
  const ScanningProgress({super.key, required this.progress});

  /// От 0 до 1.
  final double progress;

  @override
  State<ScanningProgress> createState() => _ScanningProgressState();
}

class _ScanningProgressState extends State<ScanningProgress> with SingleTickerProviderStateMixin {
  /// Оранжевая точка перебегает слева направо.
  late final _dots = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat();

  @override
  void dispose() {
    _dots.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final percent = (widget.progress.clamp(0, 1) * 100).round();
    return Padding(
      padding: EdgeInsets.fromLTRB(18, 0, 18, math.max(MediaQuery.viewPaddingOf(context).bottom + 3, 16)),
      child: SizedBox(
        height: 60,
        child: GlassPanel(
          borderRadius: BorderRadius.circular(30),
          child: Semantics(
            liveRegion: true,
            label: 'Scanning, $percent%',
            child: ExcludeSemantics(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Цифры одной ширины: пока процент растёт, надпись не дрожит.
                  Text(
                    '$percent%',
                    style: Fonts.headline.copyWith(
                      fontSize: 18,
                      height: 22.7 / 18,
                      fontWeight: FontWeight.w500,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    'Scanning',
                    style: Fonts.headline.copyWith(fontSize: 20, height: 25.2 / 20, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(width: 4),
                  AnimatedBuilder(
                    animation: _dots,
                    builder: (context, _) => _Dots(active: (_dots.value * 3).floor() % 3),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Dots extends StatelessWidget {
  const _Dots({required this.active});

  final int active;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          for (var index = 0; index < 3; index++) ...[
            if (index > 0) const SizedBox(width: 2),
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: index == active ? Appearance.accentGradient : null,
                color: index == active ? null : Appearance.surface,
                border: index == active ? null : Border.all(color: const Color(0x80FFFFFF), width: 0.5),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
