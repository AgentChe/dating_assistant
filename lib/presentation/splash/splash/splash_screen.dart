import 'dart:async';

import 'package:dating_assistant/presentation/main/main/main_screen.dart';
import 'package:dating_assistant/presentation/splash/onboarding/onboarding_screen.dart';
import 'package:dating_assistant/presentation/splash/splash/splash_view_model.dart';
import 'package:flutter/material.dart';

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
    return const Scaffold();
  }

  void _route(SplashRoute route) {
    final next = switch (route) {
      SplashRoute.onboarding => OnboardingScreen.route(),
      SplashRoute.main => MainScreen.route(),
    };
    Navigator.of(context).pushAndRemoveUntil(next, (_) => false);
  }
}
