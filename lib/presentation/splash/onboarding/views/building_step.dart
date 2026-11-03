import 'dart:math' as math;

import 'package:dating_assistant/misc/appearance.dart';
import 'package:dating_assistant/misc/assets.dart';
import 'package:dating_assistant/misc/custom_views/svg_icon.dart';
import 'package:dating_assistant/misc/extensions/profile_titles.dart';
import 'package:dating_assistant/misc/fonts.dart';
import 'package:dating_assistant/presentation/splash/onboarding/onboarding_view_model.dart';
import 'package:flutter/cupertino.dart';

/// «Tuning Cue to you»: прогресс и пункты по очереди, потом профиль сохраняется и открывается план.
class BuildingStep extends StatefulWidget {
  const BuildingStep({super.key, required this.viewModel});

  final OnboardingViewModel viewModel;

  @override
  State<BuildingStep> createState() => _BuildingStepState();
}

class _BuildingStepState extends State<BuildingStep> with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 4500));

  @override
  void initState() {
    super.initState();
    _controller
      ..addStatusListener(_onStatusChanged)
      ..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = widget.viewModel;
    final name = viewModel.name;
    final rows = [
      ('Goal', viewModel.goal?.title.toLowerCase() ?? ''),
      ('Voice', viewModel.voice.summary),
      ('Your first move', 'picking where to start'),
    ];

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final progress = _controller.value;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              const SizedBox(height: 48),
              Text(
                name == null ? 'Tuning Cue to you' : 'Tuning Cue to you, $name',
                style: Fonts.title,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              const Text('Takes a few seconds.', style: Fonts.subtitle, textAlign: TextAlign.center),
              const Spacer(flex: 100),
              _ProgressRing(progress: progress),
              const Spacer(flex: 74),
              for (final (index, (title, detail)) in rows.indexed) ...[
                if (index > 0) const SizedBox(height: 40),
                _BuildingRow(
                  title: title,
                  detail: detail,
                  state: switch (progress * rows.length) {
                    final value when value >= index + 1 => _RowState.done,
                    final value when value >= index => _RowState.active,
                    _ => _RowState.pending,
                  },
                ),
              ],
              const Spacer(flex: 92),
            ],
          ),
        );
      },
    );
  }

  void _onStatusChanged(AnimationStatus status) {
    if (status != AnimationStatus.completed) return;

    // Короткая пауза на 100%, чтобы последний пункт успел отметиться.
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) widget.viewModel.completeBuilding();
    });
  }
}

enum _RowState { pending, active, done }

class _BuildingRow extends StatelessWidget {
  const _BuildingRow({required this.title, required this.detail, required this.state});

  final String title;

  final String detail;

  final _RowState state;

  @override
  Widget build(BuildContext context) {
    final style = Fonts.body.copyWith(fontSize: 20, height: 22 / 20);
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 300),
      opacity: switch (state) {
        _RowState.pending => 0.15,
        _RowState.active => 1,
        _RowState.done => 0.5,
      },
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox.square(
              dimension: 24,
              child: state == _RowState.done
                  ? const SvgIcon(AppIcons.checkCircle)
                  : const CupertinoActivityIndicator(color: Appearance.white, radius: 10),
            ),
            const SizedBox(width: 12),
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: title,
                    style: style.copyWith(fontWeight: FontWeight.w600),
                  ),
                  TextSpan(text: ' · $detail', style: style),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Круг с процентами: тонкий трек, тёмный диск и светящаяся оранжевая дуга.
class _ProgressRing extends StatelessWidget {
  const _ProgressRing({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: 240,
      child: CustomPaint(
        painter: _ArcPainter(progress: progress),
        child: Center(
          child: Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Appearance.surface,
              border: Border.all(color: const Color(0x14FFFFFF)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Analyzing...', style: Fonts.subtitle),
                const SizedBox(height: 8),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      '${(progress * 100).round()}',
                      style: Fonts.title.copyWith(fontSize: 40, height: 50 / 40),
                    ),
                    const SizedBox(width: 4),
                    const Text('%', style: Fonts.subtitle),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ArcPainter extends CustomPainter {
  const _ArcPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    canvas.drawCircle(
      center,
      size.width / 2 - 2,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..color = const Color(0x0DFFFFFF),
    );
    if (progress <= 0) return;

    const radius = 114.0;
    final rect = Rect.fromCircle(center: center, radius: radius);
    final sweep = 2 * math.pi * progress;
    final arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;
    canvas
      ..drawArc(
        rect,
        -math.pi / 2,
        sweep,
        false,
        arc
          ..color = const Color(0x66FF7D56)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
      )
      ..drawArc(
        rect,
        -math.pi / 2,
        sweep,
        false,
        arc
          ..color = Appearance.accent
          ..maskFilter = null,
      );

    final angle = -math.pi / 2 + sweep;
    final dot = center + Offset(math.cos(angle), math.sin(angle)) * radius;
    canvas.drawCircle(
      dot,
      8,
      Paint()..shader = Appearance.accentGradient.createShader(Rect.fromCircle(center: dot, radius: 8)),
    );
  }

  @override
  bool shouldRepaint(_ArcPainter oldDelegate) => oldDelegate.progress != progress;
}
