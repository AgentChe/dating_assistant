import 'package:dating_assistant/misc/appearance.dart';
import 'package:dating_assistant/misc/assets.dart';
import 'package:dating_assistant/misc/fonts.dart';
import 'package:flutter/widgets.dart';

/// Переписка, о которой говорит коуч (context-card из Figma): «Chat attached», с кем и главный вывод.
class ChatContextCard extends StatelessWidget {
  const ChatContextCard({super.key, required this.title, this.verdict});

  /// «Nika, 28».
  final String title;

  /// «Nika is into this — and doing most of the work.»; null — вывода ещё нет.
  final String? verdict;

  @override
  Widget build(BuildContext context) {
    final verdict = this.verdict;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Appearance.surface, borderRadius: BorderRadius.circular(20)),
      child: Row(
        children: [
          Image.asset(AppImages.chat3d, width: 40, height: 40),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Chat attached', style: Fonts.eyebrow),
                const SizedBox(height: 2),
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Fonts.headline.copyWith(height: 20.16 / 16),
                ),
                if (verdict != null) ...[
                  const SizedBox(height: 2),
                  Text(verdict, style: Fonts.caption.copyWith(height: 17.64 / 14)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
