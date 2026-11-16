import 'dart:async';

import 'package:dating_assistant/misc/appearance.dart';
import 'package:dating_assistant/misc/assets.dart';
import 'package:dating_assistant/misc/custom_views/app_dialog.dart';
import 'package:dating_assistant/misc/custom_views/app_switch.dart';
import 'package:dating_assistant/misc/custom_views/screen_header.dart';
import 'package:dating_assistant/misc/custom_views/svg_icon.dart';
import 'package:dating_assistant/misc/fonts.dart';
import 'package:dating_assistant/misc/global_definitions.dart';
import 'package:dating_assistant/presentation/consent/views/privacy_facts.dart';
import 'package:dating_assistant/presentation/main/profile/ai_privacy/ai_privacy_view_model.dart';
import 'package:dating_assistant/presentation/main/profile/views/profile_section.dart';
import 'package:dating_assistant/presentation/splash/onboarding/onboarding_screen.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// «AI & privacy» (Figma 484:3499): переключатель согласия на ИИ, как это устроено, политика и удаление данных.
/// Открывается из профиля, во вкладке.
class AiPrivacyScreen extends StatefulWidget {
  const AiPrivacyScreen({super.key, this.viewModel});

  static Route<void> route() => MaterialPageRoute(builder: (_) => const AiPrivacyScreen());

  /// Для тестов; в приложении экран создаёт ViewModel сам.
  final AiPrivacyViewModel? viewModel;

  @override
  State<AiPrivacyScreen> createState() => _AiPrivacyScreenState();
}

class _AiPrivacyScreenState extends State<AiPrivacyScreen> {
  late final _viewModel = widget.viewModel ?? AiPrivacyViewModel();

  late final StreamSubscription<AiPrivacyAction> _actions;

  @override
  void initState() {
    super.initState();
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
    final padding = MediaQuery.paddingOf(context);
    return Scaffold(
      body: ListenableBuilder(
        listenable: _viewModel,
        builder: (context, _) => ListView(
          // Снизу в padding уже входит таб-бар: последний блок прокручивается над ним.
          padding: EdgeInsets.fromLTRB(16, padding.top + 11, 16, padding.bottom + 16),
          children: [
            ScreenHeader(title: 'AI & privacy', onBack: () => Navigator.of(context).pop()),
            const SizedBox(height: 28),
            _SharingCard(isAllowed: _viewModel.isSharingAllowed, onChanged: _viewModel.setSharingAllowed),
            const SizedBox(height: 24),
            const ProfileSection(title: 'How it works', child: PrivacyFacts()),
            const SizedBox(height: 24),
            ProfileSection(
              title: 'Your data',
              child: Container(
                decoration: BoxDecoration(color: Appearance.surface, borderRadius: BorderRadius.circular(20)),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    _DataRow(
                      icon: AppImages.policy3d,
                      title: 'Privacy Policy',
                      hasChevron: true,
                      onTap: _viewModel.openPrivacyPolicy,
                    ),
                    Container(height: 1, color: const Color(0x14FFFFFF)),
                    _DataRow(
                      icon: AppImages.deleteData3d,
                      title: 'Delete my data',
                      color: Appearance.red,
                      onTap: _viewModel.deleteData,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handle(AiPrivacyAction action) async {
    switch (action) {
      case AiPrivacyAction.openPrivacyPolicy:
        await launchUrl(Uri.parse(GlobalDefinitions.privacyPolicyUrl), mode: LaunchMode.inAppBrowserView);
      case AiPrivacyAction.confirmDeletion:
        final isConfirmed = await AppDialog.show(
          context,
          icon: AppIcons.trash,
          title: 'Delete your data?',
          message:
              'This erases your History, your voice and your answers from Cue. It can’t be undone. '
              'Your subscription stays active.',
          confirmTitle: 'Delete my data',
          cancelTitle: 'Cancel',
          isDestructive: true,
        );
        if (isConfirmed && mounted) await _viewModel.confirmDeletion();
      case AiPrivacyAction.dataDeleted:
        // Ответов с онбординга больше нет — приложение начинается заново, как после установки.
        await Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(OnboardingScreen.route(), (_) => false);
    }
  }
}

/// «Share chats with AI» с переключателем и подсказкой, что будет, если его выключить.
class _SharingCard extends StatelessWidget {
  const _SharingCard({required this.isAllowed, required this.onChanged});

  final bool isAllowed;

  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Appearance.surface, borderRadius: BorderRadius.circular(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              ExcludeSemantics(child: Image.asset(AppImages.chatAi3d, width: 40, height: 40)),
              const SizedBox(width: 12),
              Expanded(
                child: ExcludeSemantics(child: Text('Share chats with AI', style: Fonts.headline)),
              ),
              const SizedBox(width: 12),
              AppSwitch(value: isAllowed, onChanged: onChanged, semanticLabel: 'Share chats with AI'),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            isAllowed
                ? 'Cue needs it for breakdowns, the coach and opening lines. Turn it off and nothing new is sent.'
                : 'Off. Nothing is sent to AI, so breakdowns, the coach and opening lines are paused.',
            style: Fonts.caption,
          ),
        ],
      ),
    );
  }
}

/// Строка «Your data»: 3D-иконка и название; «Delete my data» — красным и без шеврона.
class _DataRow extends StatelessWidget {
  const _DataRow({
    required this.icon,
    required this.title,
    required this.onTap,
    this.color = Appearance.white,
    this.hasChevron = false,
  });

  final String icon;

  final String title;

  final VoidCallback onTap;

  final Color color;

  final bool hasChevron;

  @override
  Widget build(BuildContext context) {
    return MergeSemantics(
      child: Semantics(
        button: true,
        child: InkWell(
          onTap: onTap,
          highlightColor: const Color(0x0AFFFFFF),
          splashColor: Colors.transparent,
          child: Container(
            height: 56,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                ExcludeSemantics(child: Image.asset(icon, width: 32, height: 32)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: Fonts.body.copyWith(height: 20 / 16, color: color),
                  ),
                ),
                if (hasChevron) const SvgIcon(AppIcons.chevronRight, size: 20, color: Appearance.grey),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
