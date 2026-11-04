import 'package:dating_assistant/misc/assets.dart';
import 'package:dating_assistant/misc/fonts.dart';
import 'package:dating_assistant/presentation/splash/paygate/paygate_view_model.dart';
import 'package:dating_assistant/presentation/splash/paygate/views/cue_plus_badge.dart';
import 'package:dating_assistant/presentation/splash/paygate/views/paygate_copy.dart';
import 'package:dating_assistant/presentation/splash/paygate/views/paygate_hero.dart';
import 'package:dating_assistant/presentation/splash/paygate/views/plan_card.dart';
import 'package:dating_assistant/presentation/splash/paygate/views/plan_comparison.dart';
import 'package:dating_assistant/presentation/splash/paygate/views/trial_timeline.dart';
import 'package:flutter/widgets.dart';

/// Прокручиваемая часть пейгейта; шапка и низ закреплены поверх неё.
class PaygateContent extends StatelessWidget {
  const PaygateContent({super.key, required this.viewModel, required this.controller});

  final PaygateViewModel viewModel;

  final ScrollController controller;

  @override
  Widget build(BuildContext context) {
    final product = viewModel.selectedProduct;
    final trialDays = product?.freeTrialDays;
    return SingleChildScrollView(
      controller: controller,
      // Снизу — место под закрепленную кнопку.
      padding: EdgeInsets.fromLTRB(16, MediaQuery.paddingOf(context).top + 55, 16, 200),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const PaygateHero(),
          const SizedBox(height: 24),
          const Align(alignment: Alignment.centerLeft, child: CuePlusBadge()),
          const SizedBox(height: 12),
          const Text('Keep the chat going', style: Fonts.title),
          const SizedBox(height: 24),
          const _Benefit(
            icon: AppImages.question3d,
            title: 'Unlimited coach and lines',
            subtitle: 'No weekly cap — Free stops at 3',
          ),
          const SizedBox(height: 16),
          const _Benefit(
            icon: AppImages.quotes3d,
            title: 'Lines that sound like you',
            subtitle: 'Cue learns your voice from every chat',
          ),
          const SizedBox(height: 16),
          const _Benefit(
            icon: AppImages.bars3d,
            title: 'Whole-chat breakdowns',
            subtitle: 'Import from WhatsApp, see how it changed',
          ),
          const SizedBox(height: 24),
          _Plans(viewModel: viewModel),
          if (product != null && trialDays != null) ...[
            const SizedBox(height: 24),
            TrialTimeline(
              trialDays: trialDays,
              charge: '${product.price} ${viewModel.plan == PaygatePlan.weekly ? 'a week' : 'for the year'}',
            ),
          ],
          const SizedBox(height: 24),
          const PlanComparison(),
          const SizedBox(height: 24),
          const _PrivacyNote(),
        ],
      ),
    );
  }
}

class _Benefit extends StatelessWidget {
  const _Benefit({required this.icon, required this.title, required this.subtitle});

  final String icon;

  final String title;

  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Image.asset(icon, width: 40, height: 40),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Fonts.headline.copyWith(height: 20 / 16)),
              const SizedBox(height: 2),
              Text(subtitle, style: Fonts.caption),
            ],
          ),
        ),
      ],
    );
  }
}

class _Plans extends StatelessWidget {
  const _Plans({required this.viewModel});

  final PaygateViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final yearly = viewModel.yearly;
    final weekly = viewModel.weekly;
    final yearlyTrial = yearly?.freeTrialDays;
    final weeklyTrial = weekly?.freeTrialDays;
    final saving = viewModel.yearlySavingPercent;
    final pricePerWeek = viewModel.yearlyPricePerWeek;

    return Row(
      children: [
        Expanded(
          child: PlanCard(
            title: 'Yearly',
            price: yearly?.price ?? '—',
            period: '/ year',
            note: [
              if (pricePerWeek != null) '$pricePerWeek a week',
              if (yearlyTrial != null) '${PaygateCopy.trialLength(yearlyTrial)} free',
            ].join(' · '),
            badge: saving == null ? null : 'Save $saving%',
            isSelected: viewModel.plan == PaygatePlan.yearly,
            onTap: () => viewModel.selectPlan(PaygatePlan.yearly),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: PlanCard(
            title: 'Weekly',
            price: weekly?.price ?? '—',
            period: '/ week',
            note: weeklyTrial == null ? 'Cancel anytime' : '${PaygateCopy.trialLength(weeklyTrial)} free',
            isSelected: viewModel.plan == PaygatePlan.weekly,
            onTap: () => viewModel.selectPlan(PaygatePlan.weekly),
          ),
        ),
      ],
    );
  }
}

class _PrivacyNote extends StatelessWidget {
  const _PrivacyNote();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('🔒', style: TextStyle(fontSize: 16, height: 1.25)),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Your chats stay private on Plus too: screenshots and files are deleted right after the breakdown.',
              style: Fonts.caption,
            ),
          ),
        ],
      ),
    );
  }
}
