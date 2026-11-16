import 'dart:async';

import 'package:dating_assistant/misc/assets.dart';
import 'package:dating_assistant/misc/custom_views/screen_header.dart';
import 'package:dating_assistant/presentation/analysis/analyzing/analyzing_screen.dart';
import 'package:dating_assistant/presentation/opening_line/match_details/match_details_screen.dart';
import 'package:dating_assistant/presentation/opening_line/opening_line/opening_line_screen.dart';
import 'package:dating_assistant/presentation/opening_line/opening_line_source/opening_line_source_view_model.dart';
import 'package:dating_assistant/presentation/opening_line/opening_line_source/views/source_card.dart';
import 'package:dating_assistant/presentation/splash/plus_sheet/plus_sheet.dart';
import 'package:dating_assistant/service/opening_line/model/opening_line.dart';
import 'package:flutter/material.dart';

/// «Opening line» (аналог OpeningLineSourceViewController): из чего писать первую фразу.
/// Открывается во вкладке Main, таб-бар остаётся.
class OpeningLineSourceScreen extends StatefulWidget {
  const OpeningLineSourceScreen({super.key});

  static Route<void> route() => MaterialPageRoute(builder: (_) => const OpeningLineSourceScreen());

  @override
  State<OpeningLineSourceScreen> createState() => _OpeningLineSourceScreenState();
}

class _OpeningLineSourceScreenState extends State<OpeningLineSourceScreen> {
  late final _viewModel = OpeningLineSourceViewModel();

  late final StreamSubscription<OpeningLineSourceAction> _actions;

  @override
  void initState() {
    super.initState();
    _actions = _viewModel.actions.listen(_handle);
    _viewModel.load();
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
      body: ListView(
        padding: EdgeInsets.fromLTRB(16, padding.top + 11, 16, padding.bottom + 16),
        children: [
          ScreenHeader(title: 'Opening line', onBack: () => Navigator.of(context).maybePop()),
          const SizedBox(height: 56),
          SourceCard(
            icon: AppImages.galleryTile3d,
            title: 'Upload their bio',
            subtitle: 'A screenshot of their profile',
            // Картинки из Figma вместе с размытием и наклоном; выходят за край карточки, она их обрезает.
            decoration: Transform.translate(
              offset: const Offset(-37, -7),
              child: Image.asset(AppImages.bioCards, width: 121, height: 124),
            ),
            onTap: _viewModel.uploadBio,
          ),
          const SizedBox(height: 12),
          SourceCard(
            icon: AppImages.keyboardTile3d,
            title: 'Type it out',
            subtitle: 'Name, age and what they wrote',
            decoration: Transform.translate(
              offset: const Offset(18, -7),
              child: Image.asset(AppImages.messageBubbles, width: 184, height: 96.3),
            ),
            onTap: _viewModel.typeItOut,
          ),
          const SizedBox(height: 12),
          SourceCard(
            icon: AppImages.sparkleTile3d,
            title: 'Just give me one',
            subtitle: 'No details needed',
            onTap: _viewModel.giveMeOne,
          ),
        ],
      ),
    );
  }

  Future<void> _handle(OpeningLineSourceAction action) async {
    // Фраза открывается во вкладке поверх этого экрана: отсюда можно попробовать другой способ.
    final navigator = Navigator.of(context);
    switch (action) {
      case ScanBio(:final screenshot):
        final outcome = await Navigator.of(context, rootNavigator: true).push(
          AnalyzingScreen.route<OpeningLine>(
            screenshot: screenshot,
            task: () => _viewModel.generateFromBio(screenshot),
            onFinished: (line) =>
                navigator.push(OpeningLineScreen.route(session: _viewModel.keep(line), isAnimated: false)),
          ),
        );
        if (outcome == AnalyzingOutcome.limitReached && mounted) {
          _viewModel.didReachLimit();
          await _openPlus();
        }
      case TypeItOut():
        await Navigator.of(context, rootNavigator: true).push(
          MatchDetailsScreen.route(
            onSubmit: (match) => navigator.push(OpeningLineScreen.route(match: match, isAnimated: false)),
          ),
        );
      case GiveMeOne():
        await navigator.push(OpeningLineScreen.route());
      case OpenPlus():
        await _openPlus();
    }
  }

  Future<void> _openPlus() async {
    if (await PlusSheet.present(context)) _viewModel.didSubscribe();
  }
}
