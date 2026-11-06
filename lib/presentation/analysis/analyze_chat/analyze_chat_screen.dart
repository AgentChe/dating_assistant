import 'dart:async';

import 'package:dating_assistant/misc/assets.dart';
import 'package:dating_assistant/misc/custom_views/screen_header.dart';
import 'package:dating_assistant/presentation/analysis/analyze_chat/analyze_chat_view_model.dart';
import 'package:dating_assistant/presentation/analysis/analyze_chat/views/source_card.dart';
import 'package:dating_assistant/presentation/analysis/analyzing/analyzing_screen.dart';
import 'package:dating_assistant/presentation/analysis/chat_breakdown/chat_breakdown_screen.dart';
import 'package:dating_assistant/presentation/splash/plus_sheet/plus_sheet.dart';
import 'package:flutter/material.dart';

/// «Analyze your chat» (аналог AnalyzeChatViewController): скриншот из фото или импорт всей переписки.
/// Открывается во вкладке Main, таб-бар остаётся.
class AnalyzeChatScreen extends StatefulWidget {
  const AnalyzeChatScreen({super.key, this.viewModel});

  static Route<void> route() => MaterialPageRoute(builder: (_) => const AnalyzeChatScreen());

  /// Для тестов; в приложении экран создаёт ViewModel сам.
  final AnalyzeChatViewModel? viewModel;

  @override
  State<AnalyzeChatScreen> createState() => _AnalyzeChatScreenState();
}

class _AnalyzeChatScreenState extends State<AnalyzeChatScreen> {
  late final _viewModel = widget.viewModel ?? AnalyzeChatViewModel();

  late final StreamSubscription<AnalyzeChatAction> _actions;

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
          ScreenHeader(title: 'Analyze your chat', onBack: () => Navigator.of(context).maybePop()),
          const SizedBox(height: 56),
          SourceCard(
            icon: AppImages.galleryTile3d,
            title: 'Choose from photos',
            subtitle: 'Any dating app or messenger works',
            onTap: _viewModel.chooseFromPhotos,
          ),
          const SizedBox(height: 12),
          SourceCard(
            icon: AppImages.barsTile3d,
            title: 'Import the whole chat',
            subtitle: 'Message from WhatsApp, Telegram...',
            // Картинка из Figma вместе с размытием и наклоном пузырей; выходит за край карточки.
            decoration: Transform.translate(
              offset: const Offset(18, -7),
              child: Image.asset(AppImages.importBubbles, width: 184, height: 96.3),
            ),
            onTap: _viewModel.importChat,
          ),
        ],
      ),
    );
  }

  Future<void> _handle(AnalyzeChatAction action) async {
    switch (action) {
      case AnalyzeScreenshot(:final screenshot):
        // Разбор заменит этот экран во вкладке, пока сканирование ещё закрывает всё сверху.
        final navigator = Navigator.of(context);
        final outcome = await Navigator.of(context, rootNavigator: true).push(
          AnalyzingScreen.route(
            screenshot: screenshot,
            onFinished: (breakdown) =>
                navigator.pushReplacement(ChatBreakdownScreen.route(breakdown, isAnimated: false)),
          ),
        );
        if (outcome == AnalyzingOutcome.limitReached && mounted) {
          _viewModel.didReachLimit();
          await _openPlus();
        }
      case OpenPlus():
        await _openPlus();
      case ImportChat():
        // TODO: импорт всей переписки из WhatsApp и Telegram через системное «Поделиться» — отдельная фича.
        debugPrint('AnalyzeChatScreen: the chat import is not implemented yet');
    }
  }

  Future<void> _openPlus() async {
    if (await PlusSheet.present(context)) _viewModel.didSubscribe();
  }
}
