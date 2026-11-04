import 'package:dating_assistant/misc/appearance.dart';
import 'package:dating_assistant/misc/assets.dart';
import 'package:dating_assistant/misc/components/fade_page_route.dart';
import 'package:dating_assistant/misc/custom_views/bottom_buttons.dart';
import 'package:dating_assistant/misc/custom_views/primary_button.dart';
import 'package:dating_assistant/misc/fonts.dart';
import 'package:dating_assistant/presentation/splash/paygate/views/cue_plus_badge.dart';
import 'package:dating_assistant/presentation/splash/paygate/views/paygate_copy.dart';
import 'package:dating_assistant/presentation/splash/welcome_plus/welcome_plus_view_model.dart';
import 'package:flutter/material.dart';

/// «You’re in»: подписка оформлена, дальше — [onContinue].
class WelcomePlusScreen extends StatefulWidget {
  const WelcomePlusScreen({super.key, required this.trialDays, required this.onContinue});

  static Route<void> route({required int? trialDays, required void Function(BuildContext context) onContinue}) =>
      FadePageRoute(
        builder: (_) => WelcomePlusScreen(trialDays: trialDays, onContinue: onContinue),
      );

  /// Пробный период купленной подписки; null — без него (или покупку восстановили).
  final int? trialDays;

  final void Function(BuildContext context) onContinue;

  @override
  State<WelcomePlusScreen> createState() => _WelcomePlusScreenState();
}

class _WelcomePlusScreenState extends State<WelcomePlusScreen> {
  final _viewModel = WelcomePlusViewModel();

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final name = _viewModel.name;
    final trialDays = widget.trialDays;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) widget.onContinue(context);
      },
      child: Scaffold(
        backgroundColor: Appearance.black,
        body: SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 26),
              const Expanded(child: _Hero()),
              const SizedBox(height: 43),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const CuePlusBadge(),
                    const SizedBox(height: 12),
                    Text(name == null ? 'You’re in' : 'You’re in, $name', style: Fonts.title),
                    const SizedBox(height: 8),
                    const Text(
                      'No more counting. Coach messages, lines and breakdowns are unlimited now.',
                      style: Fonts.subtitle,
                    ),
                    if (trialDays != null) ...[const SizedBox(height: 12), _TrialNote(trialDays: trialDays)],
                  ],
                ),
              ),
              const SizedBox(height: 24),
              BottomButtons(
                buttons: [PrimaryButton(title: 'Let’s go', onPressed: () => widget.onContinue(context))],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 3D-иконки вокруг большой звезды — композиция 396×360 из Figma.
class _Hero extends StatelessWidget {
  const _Hero();

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: SizedBox(
        width: 396,
        height: 360,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: -32,
              top: -50,
              width: 460,
              height: 460,
              child: IgnorePointer(child: Opacity(opacity: 0.2, child: Image.asset(AppImages.glow))),
            ),
            _icon(AppImages.chat3d, left: 22, top: 11, size: 108),
            _icon(AppImages.quotes3d, left: 275, top: 34, size: 95),
            _icon(AppImages.bars3d, left: 30, top: 252, size: 81),
            _icon(AppImages.question3d, left: 282, top: 224, size: 99),
            _icon(AppImages.sparkle3d, left: 120, top: 102, size: 156),
          ],
        ),
      ),
    );
  }

  static Widget _icon(String asset, {required double left, required double top, required double size}) {
    return Positioned(
      left: left,
      top: top,
      child: Image.asset(asset, width: size, height: size),
    );
  }
}

class _TrialNote extends StatelessWidget {
  const _TrialNote({required this.trialDays});

  final int trialDays;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(color: Appearance.surface, borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          const Text('🔔', style: TextStyle(fontSize: 20, height: 1.25)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Free until ${PaygateCopy.day(PaygateCopy.trialEnd(trialDays))}',
                  style: Fonts.caption.copyWith(fontWeight: FontWeight.w600, color: Appearance.white),
                ),
                const SizedBox(height: 2),
                Text(
                  'We’ll remind you on ${PaygateCopy.day(PaygateCopy.trialReminder(trialDays))}. '
                  'Cancel anytime in Settings.',
                  style: Fonts.caption,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
