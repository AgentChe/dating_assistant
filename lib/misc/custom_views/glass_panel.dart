import 'dart:ui' show ImageFilter;

import 'package:flutter/widgets.dart';

/// Стеклянная подложка из Figma (компонент glass): размывает и затемняет то, что под ней, по краю — блик.
/// На чёрном фоне выглядит как #0F0F0F.
class GlassPanel extends StatelessWidget {
  const GlassPanel({super.key, required this.borderRadius, required this.child});

  final BorderRadius borderRadius;

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: borderRadius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        // Заливки glass_bg снизу вверх: #CCCCCC 50% в режиме Color Burn, чёрный 60%, белый 6%.
        child: DecoratedBox(
          decoration: const BoxDecoration(color: Color(0x80CCCCCC), backgroundBlendMode: BlendMode.colorBurn),
          child: DecoratedBox(
            decoration: const BoxDecoration(color: Color(0x99000000)),
            child: DecoratedBox(
              decoration: const BoxDecoration(color: Color(0x0FFFFFFF)),
              child: CustomPaint(foregroundPainter: _RimPainter(borderRadius), child: child),
            ),
          ),
        ),
      ),
    );
  }
}

/// Блик по краю, как у эффекта Glass в Figma: сверху светлее, снизу темнее.
class _RimPainter extends CustomPainter {
  const _RimPainter(this.borderRadius);

  final BorderRadius borderRadius;

  static const _width = 0.5;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = _width
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0x24FFFFFF), Color(0x16FFFFFF)],
      ).createShader(rect);
    // Линия целиком внутри формы, иначе ClipRRect срежет её половину.
    canvas.drawRRect(borderRadius.toRRect(rect).deflate(_width / 2), paint);
  }

  @override
  bool shouldRepaint(_RimPainter oldDelegate) => oldDelegate.borderRadius != borderRadius;
}
