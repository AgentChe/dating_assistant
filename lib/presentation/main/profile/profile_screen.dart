import 'dart:async';

import 'package:dating_assistant/misc/custom_views/failure_toast.dart';
import 'package:dating_assistant/misc/fonts.dart';
import 'package:dating_assistant/misc/global_definitions.dart';
import 'package:dating_assistant/presentation/main/profile/ai_privacy/ai_privacy_screen.dart';
import 'package:dating_assistant/presentation/main/profile/profile_view_model.dart';
import 'package:dating_assistant/presentation/main/profile/views/about_you_card.dart';
import 'package:dating_assistant/presentation/main/profile/views/about_you_sheet.dart';
import 'package:dating_assistant/presentation/main/profile/views/plan_section.dart';
import 'package:dating_assistant/presentation/main/profile/views/profile_row.dart';
import 'package:dating_assistant/presentation/main/profile/views/profile_section.dart';
import 'package:dating_assistant/misc/custom_views/spice_card.dart';
import 'package:dating_assistant/presentation/splash/paygate/views/paygate_copy.dart';
import 'package:dating_assistant/presentation/splash/plus_sheet/plus_sheet.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Вкладка «Profile» (аналог ProfileViewController): ответы с онбординга, которые можно поменять,
/// острота по умолчанию и план.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final _viewModel = ProfileViewModel();

  late final StreamSubscription<ProfileAction> _actions;

  @override
  void initState() {
    super.initState();
    _actions = _viewModel.actions.listen(_handle);
    _viewModel.loadPlan();
  }

  @override
  void dispose() {
    _actions.cancel();
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final padding = MediaQuery.paddingOf(context);
    return Scaffold(
      body: ListenableBuilder(
        listenable: _viewModel,
        builder: (context, _) {
          final profile = _viewModel.profile;
          final failure = _viewModel.failure;
          return Stack(
            children: [
              // Снизу в padding уже входит таб-бар: последний блок прокручивается над ним.
              SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(16, padding.top + 11, 16, padding.bottom + 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(
                      height: 48,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text('Profile', style: Fonts.title.copyWith(fontSize: 20, height: 25.2 / 20)),
                      ),
                    ),
                    const SizedBox(height: 28),
                    if (profile != null) ...[
                      ProfileSection(
                        title: 'Default spice',
                        hint: 'Saved automatically',
                        child: SpiceCard(spice: profile.spice, onChanged: _viewModel.selectSpice),
                      ),
                      const SizedBox(height: 24),
                      ProfileSection(
                        title: 'About you',
                        hint: 'Tunes your lines',
                        child: AboutYouCard(profile: profile, onTap: _viewModel.openAboutYou),
                      ),
                      const SizedBox(height: 24),
                    ],
                    PlanSection(
                      plan: _viewModel.plan,
                      isRestoring: _viewModel.isRestoring,
                      onGoUnlimited: _viewModel.goUnlimited,
                      onManageSubscription: _viewModel.manageSubscription,
                      onRestore: _viewModel.restore,
                    ),
                    const SizedBox(height: 24),
                    // Вместо прежней подписи про скриншоты — вход в «AI & privacy» (Figma 484:3403).
                    ProfileCard(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: ProfileRow(
                          emoji: '🔒',
                          title: 'AI & privacy',
                          value: _viewModel.isAiSharingAllowed ? 'On' : 'Off',
                          hasDivider: false,
                          onTap: _viewModel.openAiPrivacy,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                top: padding.top + 75,
                left: 16,
                right: 16,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: failure == null
                      ? const SizedBox.shrink()
                      : FailureToast(
                          key: ValueKey(failure),
                          message: PaygateCopy.failure(failure),
                          onTap: _viewModel.dismissFailure,
                        ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _handle(ProfileAction action) async {
    switch (action) {
      case ProfileAction.openAboutYou:
        final profile = _viewModel.profile;
        if (profile == null) return;
        final aboutYou = await AboutYouSheet.show(
          context,
          (gender: profile.gender, ageRange: profile.ageRange, goal: profile.goal),
        );
        if (aboutYou != null) await _viewModel.updateAboutYou(aboutYou);
      case ProfileAction.openPlus:
        if (await PlusSheet.present(context)) await _viewModel.loadPlan();
      case ProfileAction.openAiPrivacy:
        await Navigator.of(context).push(AiPrivacyScreen.route());
      case ProfileAction.openSubscriptions:
        final url = defaultTargetPlatform == TargetPlatform.iOS
            ? GlobalDefinitions.appStoreSubscriptionsUrl
            : GlobalDefinitions.googlePlaySubscriptionsUrl;
        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    }
  }
}
