import 'dart:async';

import 'package:dating_assistant/misc/appearance.dart';
import 'package:dating_assistant/misc/assets.dart';
import 'package:dating_assistant/misc/custom_views/app_bottom_sheet.dart';
import 'package:dating_assistant/misc/custom_views/failure_toast.dart';
import 'package:dating_assistant/misc/custom_views/pressable.dart';
import 'package:dating_assistant/misc/custom_views/primary_button.dart';
import 'package:dating_assistant/misc/custom_views/svg_icon.dart';
import 'package:dating_assistant/misc/fonts.dart';
import 'package:dating_assistant/misc/global_definitions.dart';
import 'package:dating_assistant/presentation/splash/paygate/paygate_view_model.dart';
import 'package:dating_assistant/presentation/splash/paygate/views/paygate_copy.dart';
import 'package:dating_assistant/presentation/splash/welcome_plus/welcome_plus_screen.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Подписка, оформленная в шторке: пробный период нужен экрану «You’re in».
typedef PlusPurchase = ({int? trialDays});

/// Шторка Cue Plus («No more counting»): недельный тариф, покупка и восстановление. Открывается из профиля
/// и когда бесплатные генерации на неделе кончились.
///
/// Логика та же, что у пейгейта, — общий PaygateViewModel, только тариф всегда недельный.
class PlusSheet extends StatefulWidget {
  const PlusSheet({super.key});

  /// Завершается подпиской или null, если подписки не случилось.
  static Future<PlusPurchase?> show(BuildContext context) =>
      AppBottomSheet.show<PlusPurchase>(context, builder: (_) => const PlusSheet());

  /// Шторка, а после покупки — экран «You’re in». Завершается true, как только подписка оформлена.
  static Future<bool> present(BuildContext context) async {
    final purchase = await show(context);
    if (purchase == null || !context.mounted) return false;

    unawaited(
      Navigator.of(context, rootNavigator: true).push(
        WelcomePlusScreen.route(trialDays: purchase.trialDays, onContinue: (context) => Navigator.of(context).pop()),
      ),
    );
    return true;
  }

  @override
  State<PlusSheet> createState() => _PlusSheetState();
}

class _PlusSheetState extends State<PlusSheet> {
  final _viewModel = PaygateViewModel()..selectPlan(PaygatePlan.weekly);

  late final StreamSubscription<PaygateAction> _actions;

  @override
  void initState() {
    super.initState();
    _actions = _viewModel.actions.listen(_handle);
    _viewModel.loadProducts();
  }

  @override
  void dispose() {
    _actions.cancel();
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, _) {
        final product = _viewModel.selectedProduct;
        final trialDays = product?.freeTrialDays;
        final failure = _viewModel.failure;
        final isBusy = _viewModel.isProcessing || _viewModel.isLoadingProducts;
        final (String action, VoidCallback? onAction) = switch (product) {
          null when _viewModel.hasProductsError => ('Try again', _viewModel.loadProducts),
          null => ('', null),
          _ when failure == PaygateFailure.paymentFailed => ('Try again', _viewModel.purchase),
          _ when trialDays != null => ('Start ${PaygateCopy.trialLength(trialDays)} free', _viewModel.purchase),
          final product => ('Subscribe for ${product.price} a week', _viewModel.purchase),
        };

        return PopScope(
          canPop: !_viewModel.isProcessing,
          child: AppBottomSheet(
            children: [
              if (failure != null)
                FailureToast(message: PaygateCopy.failure(failure), onTap: _viewModel.dismissFailure),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Cue Plus', style: Fonts.eyebrow),
                  SizedBox(height: 8),
                  Text('No more counting', style: Fonts.title),
                  SizedBox(height: 8),
                  Text(
                    'You’ve seen it work. Cue Plus drops the limit and adds what three generations can’t fit.',
                    style: Fonts.subtitle,
                  ),
                ],
              ),
              const Column(
                children: [
                  _Perk('Unlimited coach messages and opening lines'),
                  SizedBox(height: 12),
                  _Perk('A coach that remembers your conversations'),
                ],
              ),
              if (product != null)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(product.price, style: Fonts.title),
                    const SizedBox(width: 10),
                    Text('per week · cancel anytime', style: Fonts.caption.copyWith(height: 17.6 / 14)),
                  ],
                )
              else if (_viewModel.hasProductsError)
                const Text('Couldn’t load the plan. Check your connection.', style: Fonts.caption),
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  PrimaryButton(title: action, isLoading: isBusy, onPressed: onAction),
                  const SizedBox(height: 4),
                  PrimaryButton.plain(title: 'Not now', onPressed: _viewModel.isProcessing ? null : _viewModel.close),
                ],
              ),
              _LegalLinks(
                isEnabled: !_viewModel.isProcessing,
                onRestore: _viewModel.restore,
                onTerms: _viewModel.openTerms,
                onPrivacy: _viewModel.openPrivacy,
              ),
            ],
          ),
        );
      },
    );
  }

  void _handle(PaygateAction action) {
    switch (action) {
      case PaygateAction.close:
        Navigator.pop(context);
      case PaygateAction.subscribed:
        Navigator.pop<PlusPurchase>(context, (trialDays: _viewModel.purchasedTrialDays));
      case PaygateAction.openTerms:
        _open(GlobalDefinitions.termsOfServiceUrl);
      case PaygateAction.openPrivacy:
        _open(GlobalDefinitions.privacyPolicyUrl);
    }
  }

  Future<void> _open(String url) async {
    if (url.isEmpty) {
      debugPrint('PlusSheet: the link is not set in GlobalDefinitions');
      return;
    }
    await launchUrl(Uri.parse(url), mode: LaunchMode.inAppBrowserView);
  }
}

/// Преимущество Plus с галочкой в круге.
class _Perk extends StatelessWidget {
  const _Perk(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 24,
          height: 24,
          alignment: Alignment.center,
          decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0x1FFFFFFF)),
          child: const SvgIcon(AppIcons.check, size: 20, color: Appearance.white),
        ),
        const SizedBox(width: 12),
        Expanded(child: Text(text, style: Fonts.body)),
      ],
    );
  }
}

/// «Restore purchases · Terms · Privacy».
class _LegalLinks extends StatelessWidget {
  const _LegalLinks({required this.isEnabled, required this.onRestore, required this.onTerms, required this.onPrivacy});

  final bool isEnabled;

  final VoidCallback onRestore;

  final VoidCallback onTerms;

  final VoidCallback onPrivacy;

  @override
  Widget build(BuildContext context) {
    final style = Fonts.eyebrow.copyWith(fontWeight: FontWeight.w400);
    final separator = Text(' · ', style: style);
    return Wrap(
      alignment: WrapAlignment.center,
      children: [
        Pressable(
          onTap: isEnabled ? onRestore : null,
          child: Text('Restore purchases', style: style),
        ),
        separator,
        Pressable(
          onTap: onTerms,
          child: Text('Terms', style: style),
        ),
        separator,
        Pressable(
          onTap: onPrivacy,
          child: Text('Privacy', style: style),
        ),
      ],
    );
  }
}
