import 'package:dating_assistant/misc/appearance.dart';
import 'package:dating_assistant/misc/fonts.dart';
import 'package:dating_assistant/presentation/splash/paygate/views/paygate_copy.dart';
import 'package:flutter/widgets.dart';

/// «How your free trial works»: сегодня, напоминание и первое списание.
class TrialTimeline extends StatelessWidget {
  const TrialTimeline({super.key, required this.trialDays, required this.charge});

  final int trialDays;

  /// Что спишется после пробного периода: «$59.99 for the year».
  final String charge;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Appearance.surface, borderRadius: BorderRadius.circular(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('How your free trial works', style: Fonts.headline.copyWith(height: 20 / 16)),
          const SizedBox(height: 16),
          const _Step(
            emoji: '🔓',
            when: 'Today',
            what: 'Everything in Plus unlocks. You pay nothing.',
            isCurrent: true,
          ),
          _Step(
            emoji: '🔔',
            when: PaygateCopy.day(PaygateCopy.trialReminder(trialDays)),
            what: 'We remind you the trial ends tomorrow.',
          ),
          _Step(
            emoji: '💳',
            when: PaygateCopy.day(PaygateCopy.trialEnd(trialDays)),
            what: '$charge. Cancel before to pay nothing.',
            isLast: true,
          ),
        ],
      ),
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({
    required this.emoji,
    required this.when,
    required this.what,
    this.isCurrent = false,
    this.isLast = false,
  });

  final String emoji;

  final String when;

  final String what;

  /// Сегодняшний шаг выделен белым кружком.
  final bool isCurrent;

  /// У последнего шага нет линии к следующему.
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 32,
            child: Column(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isCurrent ? Appearance.white : Appearance.surfaceRaised,
                  ),
                  child: Text(emoji, style: const TextStyle(fontSize: 16, height: 1.25)),
                ),
                if (!isLast)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Container(
                        width: 2,
                        decoration: BoxDecoration(
                          color: Appearance.surfaceRaised,
                          borderRadius: BorderRadius.circular(1),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(top: 5, bottom: isLast ? 0 : 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    when,
                    style: Fonts.caption.copyWith(fontWeight: FontWeight.w600, color: Appearance.white),
                  ),
                  const SizedBox(height: 2),
                  Text(what, style: Fonts.caption),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
