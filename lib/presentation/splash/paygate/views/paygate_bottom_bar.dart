import 'dart:math' as math;

import 'package:dating_assistant/misc/appearance.dart';
import 'package:dating_assistant/misc/custom_views/pressable.dart';
import 'package:dating_assistant/misc/custom_views/primary_button.dart';
import 'package:dating_assistant/misc/fonts.dart';
import 'package:dating_assistant/presentation/splash/paygate/paygate_view_model.dart';
import 'package:dating_assistant/presentation/splash/paygate/views/paygate_copy.dart';
import 'package:flutter/widgets.dart';

/// Закрепленный низ пейгейта: условия выбранного тарифа, кнопка покупки и ссылки.
class PaygateBottomBar extends StatelessWidget {
  const PaygateBottomBar({super.key, required this.viewModel});

  final PaygateViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final product = viewModel.selectedProduct;
    final trialDays = product?.freeTrialDays;
    final isWeekly = viewModel.plan == PaygatePlan.weekly;

    // Условия выбранного тарифа: первая фраза белая, остальное серое.
    final (String headline, String details, String action) = switch (product) {
      null when viewModel.hasProductsError => ('Couldn’t load the plans.', ' Check your connection.', 'Try again'),
      null => ('', '', ''),
      final product when trialDays != null => (
        '${PaygateCopy.trialLength(trialDays)} free, then ${product.price} a ${isWeekly ? 'week' : 'year'}.',
        ' We’ll remind you the day before it ends.',
        'Start ${PaygateCopy.trialLength(trialDays)} free',
      ),
      final product when isWeekly => (
        'Billed every week.',
        ' Cancel anytime in Settings, and Plus stays on until the week ends.',
        'Subscribe for ${product.price} a week',
      ),
      final product => (
        '${product.price} a year.',
        ' Cancel anytime in Settings.',
        'Subscribe for ${product.price} a year',
      ),
    };
    final isFailed = viewModel.failure == PaygateFailure.paymentFailed;

    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0x00000000), Appearance.black, Appearance.black],
          stops: [0, 0.14, 1],
        ),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 24, 16, math.max(MediaQuery.paddingOf(context).bottom - 6, 16)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: headline,
                    style: const TextStyle(color: Appearance.white),
                  ),
                  TextSpan(text: details),
                ],
              ),
              style: Fonts.caption,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            PrimaryButton(
              title: isFailed ? 'Try again' : action,
              isLoading: viewModel.isProcessing || viewModel.isLoadingProducts,
              onPressed: product == null
                  ? viewModel.hasProductsError
                        ? viewModel.loadProducts
                        : null
                  : viewModel.purchase,
            ),
            const SizedBox(height: 12),
            _LegalLinks(
              prefix: isWeekly ? 'Renews weekly' : 'Cancel anytime in Settings',
              onTerms: viewModel.openTerms,
              onPrivacy: viewModel.openPrivacy,
            ),
          ],
        ),
      ),
    );
  }
}

/// «Cancel anytime in Settings · Terms · Privacy».
class _LegalLinks extends StatelessWidget {
  const _LegalLinks({required this.prefix, required this.onTerms, required this.onPrivacy});

  final String prefix;

  final VoidCallback onTerms;

  final VoidCallback onPrivacy;

  @override
  Widget build(BuildContext context) {
    const separator = Text('  ·  ', style: _style);
    // Wrap, а не Row: на узком экране или с крупным системным шрифтом ссылки переносятся.
    return Wrap(
      alignment: WrapAlignment.center,
      children: [
        Text(prefix, style: _style),
        separator,
        Pressable(
          onTap: onTerms,
          child: const Text('Terms', style: _style),
        ),
        separator,
        Pressable(
          onTap: onPrivacy,
          child: const Text('Privacy', style: _style),
        ),
      ],
    );
  }

  static const _style = TextStyle(
    fontFamily: Fonts.family,
    fontSize: 12,
    height: 15 / 12,
    color: Appearance.grey,
    leadingDistribution: TextLeadingDistribution.even,
  );
}
