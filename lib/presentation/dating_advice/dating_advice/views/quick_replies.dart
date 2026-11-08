import 'package:dating_assistant/misc/custom_views/pill_chip.dart';
import 'package:flutter/widgets.dart';

/// Быстрые ответы над полем ввода (quick-replies из Figma): чипы в ряд, лишние уходят за край экрана.
class QuickReplies extends StatelessWidget {
  const QuickReplies({super.key, required this.replies, required this.onTap});

  final List<String> replies;

  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: replies.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final reply = replies[index];
          return PillChip(label: reply, isSelected: false, onTap: () => onTap(reply));
        },
      ),
    );
  }
}
