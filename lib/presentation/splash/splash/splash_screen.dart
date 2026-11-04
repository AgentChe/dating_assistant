import 'dart:async';

import 'package:dating_assistant/misc/appearance.dart';
import 'package:dating_assistant/misc/assets.dart';
import 'package:dating_assistant/misc/fonts.dart';
import 'package:dating_assistant/presentation/main/main/main_screen.dart';
import 'package:dating_assistant/presentation/splash/onboarding/onboarding_screen.dart';
import 'package:dating_assistant/presentation/splash/paygate/paygate_screen.dart';
import 'package:dating_assistant/presentation/splash/splash/splash_view_model.dart';
import 'package:flutter/material.dart';

/// Сплэш повторяет нативный экран запуска (иконка по центру), поэтому переход к Flutter незаметен.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final _viewModel = SplashViewModel();

  late final StreamSubscription<SplashRoute> _routes;

  @override
  void initState() {
    super.initState();
    _routes = _viewModel.actions.listen(_route);
    _viewModel.start();
  }

  @override
  void dispose() {
    _routes.cancel();
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Appearance.black,
      body: Stack(
        children: [
          Center(child: Image.asset(AppImages.splashIcon, width: 128, height: 128)),
          Positioned(
            left: 0,
            right: 0,
            bottom: MediaQuery.paddingOf(context).bottom + 46,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(AppImages.splashWordmark, width: 106, height: 39),
                Text(
                  'Dating assistant',
                  style: Fonts.label.copyWith(fontWeight: FontWeight.w400, color: Appearance.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _route(SplashRoute route) {
    final next = switch (route) {
      SplashRoute.onboarding => OnboardingScreen.route(),
      SplashRoute.paygate => PaygateScreen.route(onFinish: MainScreen.setAsRoot),
      SplashRoute.main => MainScreen.route(),
    };
    Navigator.of(context).pushAndRemoveUntil(next, (_) => false);
  }
}
