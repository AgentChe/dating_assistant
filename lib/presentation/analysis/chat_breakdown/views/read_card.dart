import 'package:dating_assistant/misc/appearance.dart';
import 'package:dating_assistant/misc/fonts.dart';
import 'package:dating_assistant/service/analysis/model/chat_breakdown.dart';
import 'package:flutter/widgets.dart';

/// Пастельная карточка «The read»: главный вывод разбора и эмодзи справа.
class ReadCard extends StatelessWidget {
  const ReadCard({super.key, required this.read});

  final ChatRead read;

  @override
  Widget build(BuildContext context) {
    const muted = Color(0x99000000);
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      decoration: BoxDecoration(gradient: Appearance.pastelGradient, borderRadius: BorderRadius.circular(24)),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'The read',
                  style: Fonts.eyebrow.copyWith(fontWeight: FontWeight.w300, color: muted),
                ),
                const SizedBox(height: 4),
                Text(read.verdict, style: Fonts.title.copyWith(color: Appearance.black)),
                const SizedBox(height: 4),
                Text(
                  read.detail,
                  style: Fonts.subtitle.copyWith(height: 20.2 / 16, color: muted),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          ExcludeSemantics(
            child: Text(read.emoji, style: Fonts.body.copyWith(fontSize: 44, height: 55.4 / 44)),
          ),
        ],
      ),
    );
  }
}
