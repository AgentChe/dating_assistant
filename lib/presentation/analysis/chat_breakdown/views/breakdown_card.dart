import 'package:dating_assistant/misc/appearance.dart';
import 'package:dating_assistant/misc/fonts.dart';
import 'package:dating_assistant/service/analysis/model/chat_breakdown.dart';
import 'package:flutter/widgets.dart';

/// Стили разбора из Figma.
abstract final class BreakdownStyles {
  /// 16/20 SemiBold — заголовки карточек.
  static final title = Fonts.headline.copyWith(height: 20.2 / 16);

  /// 14/18 SemiBold — «Nika», «Asked about you».
  static final label = Fonts.label.copyWith(fontWeight: FontWeight.w600, height: 17.6 / 14);

  /// 14/18 Regular серый — значения и доказательства.
  static final value = Fonts.caption.copyWith(height: 17.6 / 14);

  /// 12/15 серый — подписи внизу карточек.
  static final note = Fonts.eyebrow.copyWith(fontWeight: FontWeight.w400);
}

/// Карточка разбора: эмодзи в круге, заголовок и содержимое через 12.
class BreakdownCard extends StatelessWidget {
  const BreakdownCard({super.key, required this.emoji, required this.title, required this.children});

  final String emoji;

  final String title;

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Appearance.surface, borderRadius: BorderRadius.circular(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: const BoxDecoration(shape: BoxShape.circle, color: Appearance.surfaceRaised),
              child: ExcludeSemantics(
                child: Text(emoji, style: Fonts.body.copyWith(fontSize: 20, height: 25.2 / 20)),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(title, style: BreakdownStyles.title),
          for (final child in children) ...[const SizedBox(height: 12), child],
        ],
      ),
    );
  }
}

/// Две карточки в ряд одной высоты; если второй нет, первая на всю ширину.
class BreakdownRow extends StatelessWidget {
  const BreakdownRow({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (index, child) in children.indexed) ...[
            if (index > 0) const SizedBox(width: 12),
            Expanded(child: child),
          ],
        ],
      ),
    );
  }
}

/// «Nika — Warm» и шкала из пяти делений.
class InterestMeter extends StatelessWidget {
  const InterestMeter({super.key, required this.who, required this.interest, required this.color});

  final String who;

  final InterestLevel interest;

  /// Оранжевый у собеседника, серый у пользователя.
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Labels(who: who, value: interest.label, color: color),
        const SizedBox(height: 8),
        Row(
          children: [
            for (var step = 0; step < ChatBreakdown.interestSteps; step++) ...[
              if (step > 0) const SizedBox(width: 4),
              Expanded(
                child: Container(
                  height: 6,
                  decoration: BoxDecoration(
                    color: step < interest.level ? color : Appearance.surfaceRaised,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

/// «Nika — 70%» и полоска доли.
class ShareBar extends StatelessWidget {
  const ShareBar({super.key, required this.who, required this.percent, required this.color});

  final String who;

  final int percent;

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Labels(who: who, value: '$percent%', color: color),
        const SizedBox(height: 8),
        Container(
          height: 6,
          alignment: Alignment.centerLeft,
          decoration: BoxDecoration(color: Appearance.surfaceRaised, borderRadius: BorderRadius.circular(3)),
          child: FractionallySizedBox(
            widthFactor: (percent / 100).clamp(0, 1),
            child: DecoratedBox(
              decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3)),
              child: const SizedBox.expand(),
            ),
          ),
        ),
      ],
    );
  }
}

class _Labels extends StatelessWidget {
  const _Labels({required this.who, required this.value, required this.color});

  final String who;

  final String value;

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(who, style: BreakdownStyles.label, maxLines: 1, overflow: TextOverflow.ellipsis),
        ),
        Text(value, style: BreakdownStyles.value.copyWith(color: color)),
      ],
    );
  }
}

/// «Asked about you» и доказательство из переписки.
class SignalItem extends StatelessWidget {
  const SignalItem({super.key, required this.signal});

  final ChatSignal signal;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(signal.title, style: BreakdownStyles.label),
        const SizedBox(height: 2),
        Text(signal.proof, style: BreakdownStyles.value),
      ],
    );
  }
}

/// «Nika» и манера переписки в пилюле справа.
class VibeRow extends StatelessWidget {
  const VibeRow({super.key, required this.who, required this.vibe});

  final String who;

  final ChatVibe vibe;

  @override
  Widget build(BuildContext context) {
    // Длинная манера или крупный шрифт: пилюля сжимается и обрезает текст, имя не уступает место.
    return Row(
      children: [
        Text(who, style: BreakdownStyles.value),
        const SizedBox(width: 8),
        const Spacer(),
        Flexible(
          flex: 8,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: const ShapeDecoration(shape: StadiumBorder(), color: Appearance.surfaceRaised),
            child: Text(
              '${vibe.emoji} ${vibe.label}',
              style: Fonts.label.copyWith(height: 17.6 / 14),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ],
    );
  }
}
