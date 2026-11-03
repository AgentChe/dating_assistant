import 'package:dating_assistant/misc/appearance.dart';
import 'package:flutter/widgets.dart';

/// Карточка с пастельным градиентом из Figma (card/swipe, voice-card, plan-card).
class PastelCard extends StatelessWidget {
  const PastelCard({super.key, required this.child, this.padding = const EdgeInsets.all(24), this.radius = 24});

  final Widget child;

  final EdgeInsetsGeometry padding;

  final double radius;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(gradient: Appearance.pastelGradient, borderRadius: BorderRadius.circular(radius)),
      child: Padding(padding: padding, child: child),
    );
  }
}
