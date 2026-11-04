import 'dart:async';

import 'package:dating_assistant/misc/appearance.dart';
import 'package:dating_assistant/misc/components/fade_page_route.dart';
import 'package:dating_assistant/misc/global_definitions.dart';
import 'package:dating_assistant/presentation/splash/paygate/paygate_view_model.dart';
import 'package:dating_assistant/presentation/splash/paygate/views/failure_toast.dart';
import 'package:dating_assistant/presentation/splash/paygate/views/paygate_bottom_bar.dart';
import 'package:dating_assistant/presentation/splash/paygate/views/paygate_content.dart';
import 'package:dating_assistant/presentation/splash/paygate/views/paygate_top_bar.dart';
import 'package:dating_assistant/presentation/splash/welcome_plus/welcome_plus_screen.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Что делать, когда пейгейт закрыли или после покупки прошли экран «You’re in».
typedef PaygateCompletion = void Function(BuildContext context);

/// Пейгейт Cue Plus (аналог PaygateViewController из Swift-проектов).
class PaygateScreen extends StatefulWidget {
  const PaygateScreen({super.key, required this.onFinish});

  /// Как PaygateViewController.make(completion:).
  static Route<void> route({required PaygateCompletion onFinish}) =>
      FadePageRoute(builder: (_) => PaygateScreen(onFinish: onFinish));

  final PaygateCompletion onFinish;

  @override
  State<PaygateScreen> createState() => _PaygateScreenState();
}

class _PaygateScreenState extends State<PaygateScreen> {
  final _viewModel = PaygateViewModel();

  final _scrollController = ScrollController();

  late final StreamSubscription<PaygateAction> _actions;

  var _isScrolled = false;

  @override
  void initState() {
    super.initState();
    _actions = _viewModel.actions.listen(_handle);
    _scrollController.addListener(_onScroll);
    _viewModel.loadProducts();
  }

  @override
  void dispose() {
    _actions.cancel();
    _scrollController.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, _) {
        final failure = _viewModel.failure;
        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) _viewModel.close();
          },
          child: Scaffold(
            backgroundColor: Appearance.black,
            body: Stack(
              children: [
                Positioned.fill(
                  child: PaygateContent(viewModel: _viewModel, controller: _scrollController),
                ),
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: PaygateTopBar(
                    isScrolled: _isScrolled,
                    isEnabled: !_viewModel.isProcessing,
                    onClose: _viewModel.close,
                    onRestore: _viewModel.restore,
                  ),
                ),
                Positioned(left: 0, right: 0, bottom: 0, child: PaygateBottomBar(viewModel: _viewModel)),
                Positioned(
                  top: MediaQuery.paddingOf(context).top + 75,
                  left: 16,
                  right: 16,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: failure == null
                        ? const SizedBox.shrink()
                        : FailureToast(key: ValueKey(failure), failure: failure, onTap: _viewModel.dismissFailure),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _onScroll() {
    final isScrolled = _scrollController.offset > 0;
    if (isScrolled != _isScrolled) setState(() => _isScrolled = isScrolled);
  }

  void _handle(PaygateAction action) {
    switch (action) {
      case PaygateAction.close:
        widget.onFinish(context);
      case PaygateAction.subscribed:
        Navigator.of(
          context,
        ).push(WelcomePlusScreen.route(trialDays: _viewModel.purchasedTrialDays, onContinue: widget.onFinish));
      case PaygateAction.openTerms:
        _open(GlobalDefinitions.termsOfServiceUrl);
      case PaygateAction.openPrivacy:
        _open(GlobalDefinitions.privacyPolicyUrl);
    }
  }

  Future<void> _open(String url) async {
    if (url.isEmpty) {
      debugPrint('PaygateScreen: the link is not set in GlobalDefinitions');
      return;
    }
    await launchUrl(Uri.parse(url), mode: LaunchMode.inAppBrowserView);
  }
}
