import 'package:dating_assistant/misc/appearance.dart';
import 'package:dating_assistant/misc/custom_views/primary_button.dart';
import 'package:dating_assistant/misc/fonts.dart';
import 'package:dating_assistant/presentation/main/profile/profile_view_model.dart';
import 'package:dating_assistant/presentation/main/profile/views/profile_section.dart';
import 'package:dating_assistant/presentation/splash/paygate/views/paygate_copy.dart';
import 'package:dating_assistant/service/usage/model/usage.dart';
import 'package:flutter/widgets.dart';

/// Карточка плана — бесплатный или Cue Plus — и «Restore purchases» под ней.
class PlanSection extends StatelessWidget {
  const PlanSection({
    super.key,
    required this.plan,
    required this.isRestoring,
    required this.onGoUnlimited,
    required this.onManageSubscription,
    required this.onRestore,
  });

  /// null, пока план загружается.
  final ProfilePlan? plan;

  final bool isRestoring;

  final VoidCallback onGoUnlimited;

  final VoidCallback onManageSubscription;

  final VoidCallback onRestore;

  @override
  Widget build(BuildContext context) {
    final plan = this.plan;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AnimatedSize(
          duration: const Duration(milliseconds: 250),
          alignment: Alignment.topCenter,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: switch (plan) {
              null => const SizedBox(width: double.infinity),
              FreePlan(:final usage) => _FreeCard(usage: usage, onGoUnlimited: onGoUnlimited),
              PlusPlan() => _PlusCard(plan: plan, onManageSubscription: onManageSubscription),
            },
          ),
        ),
        const SizedBox(height: 4),
        PrimaryButton.plain(title: 'Restore purchases', isLoading: isRestoring, onPressed: onRestore),
      ],
    );
  }
}

class _FreeCard extends StatelessWidget {
  const _FreeCard({required this.usage, required this.onGoUnlimited});

  final Usage? usage;

  final VoidCallback onGoUnlimited;

  @override
  Widget build(BuildContext context) {
    final usage = this.usage;
    return ProfileCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _PlanHead(
            emoji: '🎁',
            title: Text('Free plan', style: ProfileSection.titleStyle),
            subtitle: usage == null ? null : '${usage.left} of ${usage.limit} free generations left',
          ),
          if (usage != null) ...[const SizedBox(height: 12), _Meter(usage: usage)],
          const SizedBox(height: 12),
          PrimaryButton(title: 'Go unlimited', onPressed: onGoUnlimited),
        ],
      ),
    );
  }
}

class _PlusCard extends StatelessWidget {
  const _PlusCard({required this.plan, required this.onManageSubscription});

  final PlusPlan plan;

  final VoidCallback onManageSubscription;

  @override
  Widget build(BuildContext context) {
    final subscription = plan.subscription;
    return ProfileCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _PlanHead(
            emoji: '✨',
            title: Row(
              children: [
                Text('Cue Plus', style: ProfileSection.titleStyle),
                if (subscription?.isTrial ?? false) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: const ShapeDecoration(shape: StadiumBorder(), color: Color(0x1FFFFFFF)),
                    child: Text('Free trial', style: Fonts.eyebrow.copyWith(color: Appearance.white)),
                  ),
                ],
              ],
            ),
            subtitle: _subtitle,
          ),
          const SizedBox(height: 12),
          PrimaryButton.secondary(title: 'Manage subscription', onPressed: onManageSubscription),
        ],
      ),
    );
  }

  /// «Ends Sep 23, then $7.99 per week».
  String get _subtitle {
    final subscription = plan.subscription;
    final end = subscription?.expiresAt;
    if (subscription == null || end == null) return 'Unlimited coach messages and lines';

    final day = PaygateCopy.day(end);
    final price = plan.price;
    if (!subscription.willRenew) return 'Ends $day';
    if (subscription.isTrial) return price == null ? 'Ends $day' : 'Ends $day, then $price';
    return price == null ? 'Renews $day' : 'Renews $day · $price';
  }
}

/// Значок плана, название и подпись.
class _PlanHead extends StatelessWidget {
  const _PlanHead({required this.emoji, required this.title, required this.subtitle});

  final String emoji;

  final Widget title;

  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final subtitle = this.subtitle;
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          decoration: const BoxDecoration(shape: BoxShape.circle, color: Appearance.surfaceRaised),
          child: Text(emoji, style: Fonts.body.copyWith(fontSize: 20, height: 25.2 / 20)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              title,
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(subtitle, style: Fonts.caption.copyWith(height: 17.6 / 14)),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// Сколько бесплатных генераций осталось: по полоске на каждую.
class _Meter extends StatelessWidget {
  const _Meter({required this.usage});

  final Usage usage;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var index = 0; index < usage.limit; index++) ...[
          if (index > 0) const SizedBox(width: 6),
          Expanded(
            child: Container(
              height: 6,
              decoration: BoxDecoration(
                color: index < usage.left ? Appearance.accent : Appearance.surfaceRaised,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
