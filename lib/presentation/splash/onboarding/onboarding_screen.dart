import 'dart:async';

import 'package:animations/animations.dart';
import 'package:dating_assistant/misc/appearance.dart';
import 'package:dating_assistant/misc/assets.dart';
import 'package:dating_assistant/misc/components/fade_page_route.dart';
import 'package:dating_assistant/misc/custom_views/try_again_sheet.dart';
import 'package:dating_assistant/presentation/main/main/main_screen.dart';
import 'package:dating_assistant/presentation/splash/onboarding/onboarding_view_model.dart';
import 'package:dating_assistant/presentation/splash/onboarding/views/about_you_step.dart';
import 'package:dating_assistant/presentation/splash/onboarding/views/building_step.dart';
import 'package:dating_assistant/presentation/splash/onboarding/views/goal_step.dart';
import 'package:dating_assistant/presentation/splash/onboarding/views/hardest_part_step.dart';
import 'package:dating_assistant/presentation/splash/onboarding/views/insight_step.dart';
import 'package:dating_assistant/presentation/splash/onboarding/views/name_step.dart';
import 'package:dating_assistant/presentation/splash/onboarding/views/onboarding_header.dart';
import 'package:dating_assistant/presentation/splash/onboarding/views/plan_step.dart';
import 'package:dating_assistant/presentation/splash/onboarding/views/reveal_step.dart';
import 'package:dating_assistant/presentation/splash/onboarding/views/try_it_step.dart';
import 'package:dating_assistant/presentation/splash/onboarding/views/voice_step.dart';
import 'package:dating_assistant/presentation/splash/onboarding/views/welcome_step.dart';
import 'package:dating_assistant/presentation/splash/onboarding/views/your_voice_step.dart';
import 'package:flutter/material.dart';

/// Онбординг: шаги сменяют друг друга на одном экране, шапка с прогрессом остаётся на месте.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  static Route<void> route() => FadePageRoute(builder: (_) => const OnboardingScreen());

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _viewModel = OnboardingViewModel();

  late final StreamSubscription<OnboardingAction> _actions;

  late var _step = _viewModel.step;

  @override
  void initState() {
    super.initState();
    _viewModel.tryAgain = (error) => TryAgainSheet.show(context, error);
    _viewModel.addListener(_onChange);
    _actions = _viewModel.actions.listen(_handle);
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
        final step = _viewModel.step;
        return PopScope(
          canPop: step == OnboardingStep.welcome,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) _viewModel.back();
          },
          child: Scaffold(
            backgroundColor: Appearance.black,
            body: Stack(
              children: [
                _InsightGlow(isVisible: step == OnboardingStep.insight),
                SafeArea(
                  bottom: false,
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: PageTransitionSwitcher(
                          reverse: _viewModel.isMovingBack,
                          duration: const Duration(milliseconds: 400),
                          layoutBuilder: (entries) => Stack(fit: StackFit.expand, children: entries),
                          transitionBuilder: (child, animation, secondaryAnimation) => SharedAxisTransition(
                            animation: animation,
                            secondaryAnimation: secondaryAnimation,
                            transitionType: SharedAxisTransitionType.horizontal,
                            fillColor: Colors.transparent,
                            child: child,
                          ),
                          child: KeyedSubtree(key: ValueKey(step), child: _stepView(step)),
                        ),
                      ),
                      Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        child: IgnorePointer(
                          ignoring: !step.hasHeader,
                          child: AnimatedOpacity(
                            opacity: step.hasHeader ? 1 : 0,
                            duration: const Duration(milliseconds: 250),
                            child: OnboardingHeader(
                              progress: _viewModel.progress,
                              onBack: _viewModel.back,
                              onSkip: step == OnboardingStep.name ? _viewModel.skipName : null,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _stepView(OnboardingStep step) => switch (step) {
    OnboardingStep.welcome => WelcomeStep(viewModel: _viewModel),
    OnboardingStep.name => NameStep(viewModel: _viewModel),
    OnboardingStep.goal => GoalStep(viewModel: _viewModel),
    OnboardingStep.aboutYou => AboutYouStep(viewModel: _viewModel),
    OnboardingStep.hardestPart => HardestPartStep(viewModel: _viewModel),
    OnboardingStep.insight => InsightStep(viewModel: _viewModel),
    OnboardingStep.voice => VoiceStep(index: _viewModel.voiceSampleIndex, onAnswer: _viewModel.answerVoice),
    OnboardingStep.yourVoice => YourVoiceStep(viewModel: _viewModel),
    OnboardingStep.tryIt => TryItStep(viewModel: _viewModel),
    OnboardingStep.reveal => RevealStep(viewModel: _viewModel),
    OnboardingStep.building => BuildingStep(viewModel: _viewModel),
    OnboardingStep.plan => PlanStep(viewModel: _viewModel),
  };

  /// Клавиатура с шага имени не должна переезжать на следующий шаг.
  void _onChange() {
    if (_step == _viewModel.step) return;

    _step = _viewModel.step;
    FocusManager.instance.primaryFocus?.unfocus();
  }

  void _handle(OnboardingAction action) {
    switch (action) {
      case OnboardingAction.finished:
        Navigator.of(context).pushAndRemoveUntil(MainScreen.route(), (_) => false);
    }
  }
}

/// Свечение за иконкой на шаге «Made for you» заходит под шапку, поэтому живёт на уровне экрана.
class _InsightGlow extends StatelessWidget {
  const _InsightGlow({required this.isVisible});

  static const _size = 440.0;

  final bool isVisible;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: MediaQuery.paddingOf(context).top + 1,
      left: (MediaQuery.sizeOf(context).width - _size) / 2,
      width: _size,
      height: _size,
      child: IgnorePointer(
        child: AnimatedOpacity(
          opacity: isVisible ? 0.2 : 0,
          duration: const Duration(milliseconds: 400),
          child: Image.asset(AppImages.glow),
        ),
      ),
    );
  }
}
