import 'dart:math' as math;

import 'package:dating_assistant/misc/appearance.dart';
import 'package:dating_assistant/presentation/dating_advice/dating_advice/views/chat_bubble.dart';
import 'package:flutter/widgets.dart';

/// Коуч печатает (typing из Figma): три точки, по которым бежит волна яркости.
class TypingBubble extends StatefulWidget {
  const TypingBubble({super.key});

  @override
  State<TypingBubble> createState() => _TypingBubbleState();
}

class _TypingBubbleState extends State<TypingBubble> with SingleTickerProviderStateMixin {
  late final _wave = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat();

  @override
  void dispose() {
    _wave.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Coach is typing',
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(color: Appearance.surfaceRaised, borderRadius: ChatBubble.coachRadius),
          child: AnimatedBuilder(
            animation: _wave,
            builder: (context, _) => Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var index = 0; index < 3; index++) ...[
                  if (index > 0) const SizedBox(width: 5),
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Appearance.grey.withValues(alpha: _opacity(index)),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Как в макете: первая точка ярче всех (100%, 60%, 30%), и волна идёт слева направо.
  double _opacity(int index) {
    final phase = (_wave.value - index * 0.2) % 1;
    return 0.3 + 0.7 * (0.5 + 0.5 * math.cos(2 * math.pi * phase));
  }
}
