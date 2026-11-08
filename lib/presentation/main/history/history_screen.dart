import 'dart:async';

import 'package:dating_assistant/misc/assets.dart';
import 'package:dating_assistant/misc/custom_views/app_dialog.dart';
import 'package:dating_assistant/misc/custom_views/glass_toast.dart';
import 'package:dating_assistant/misc/custom_views/screen_header.dart';
import 'package:dating_assistant/misc/extensions/history_titles.dart';
import 'package:dating_assistant/misc/fonts.dart';
import 'package:dating_assistant/presentation/analysis/analyzing/analyzing_screen.dart';
import 'package:dating_assistant/presentation/analysis/chat_breakdown/chat_breakdown_screen.dart';
import 'package:dating_assistant/presentation/dating_advice/dating_advice/dating_advice_screen.dart';
import 'package:dating_assistant/presentation/main/history/history_view_model.dart';
import 'package:dating_assistant/presentation/main/history/views/history_empty.dart';
import 'package:dating_assistant/presentation/main/history/views/history_row.dart';
import 'package:dating_assistant/presentation/main/history/views/history_search_field.dart';
import 'package:dating_assistant/presentation/main/history/views/swipe_to_delete.dart';
import 'package:dating_assistant/presentation/opening_line/opening_line/opening_line_screen.dart';
import 'package:dating_assistant/presentation/splash/plus_sheet/plus_sheet.dart';
import 'package:dating_assistant/service/analysis/model/chat_breakdown.dart';
import 'package:dating_assistant/service/history/model/history_item.dart';
import 'package:flutter/material.dart';

/// Вкладка «History» (аналог HistoryViewController): разборы, разговоры с коучем и первые фразы, новые сверху.
/// Запись открывается во вкладке, а коуч — поверх таб-бара, как и с главной.
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key, this.viewModel});

  /// Для тестов; в приложении экран создаёт ViewModel сам.
  final HistoryViewModel? viewModel;

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  late final _viewModel = widget.viewModel ?? HistoryViewModel();

  late final StreamSubscription<HistoryAction> _actions;

  /// Строка, у которой свайпом открыто удаление; открытой бывает только одна.
  String? _openRowId;

  /// Плашка «Conversation deleted · Undo» живёт около трёх секунд.
  Timer? _undoTimer;

  @override
  void initState() {
    super.initState();
    _actions = _viewModel.actions.listen(_handle);
    _viewModel.start();
  }

  @override
  void dispose() {
    _undoTimer?.cancel();
    _actions.cancel();
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final padding = MediaQuery.paddingOf(context);
    // Снизу в padding уже входит таб-бар: последняя запись прокручивается над ним.
    final insets = EdgeInsets.fromLTRB(16, padding.top + 11, 16, padding.bottom + 16);
    // Вкладка — корень своего стека, поэтому без «назад», хотя в макете он нарисован.
    final header = SizedBox(
      height: 48,
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text('History', style: ScreenHeader.titleStyle),
      ),
    );

    return Scaffold(
      body: ListenableBuilder(
        listenable: _viewModel,
        builder: (context, _) => Stack(
          children: [
            if (_viewModel.isEmpty)
              Padding(
                padding: insets,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    header,
                    Expanded(
                      child: Center(child: HistoryEmpty(onAnalyze: _viewModel.analyzeChat)),
                    ),
                  ],
                ),
              )
            else
              // Список поехал — открытое удаление закрывается, как в iOS.
              NotificationListener<ScrollStartNotification>(
                onNotification: (_) {
                  if (_openRowId != null) setState(() => _openRowId = null);
                  return false;
                },
                child: ListView(
                  padding: insets,
                  keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                  children: [
                    header,
                    const SizedBox(height: 28),
                    HistorySearchField(onChanged: _viewModel.search),
                    const SizedBox(height: 32),
                    Text(_viewModel.countLabel, style: Fonts.subtitle.copyWith(height: 20.16 / 16)),
                    const SizedBox(height: 12),
                    for (final (index, item) in _viewModel.items.indexed) ...[
                      if (index > 0) const SizedBox(height: 8),
                      SwipeToDelete(
                        key: ValueKey(item.id),
                        isOpen: item.id == _openRowId,
                        onOpenChanged: (isOpen) => setState(() => _openRowId = isOpen ? item.id : null),
                        onDelete: () => _confirmDelete(item),
                        child: HistoryRow(
                          icon: _icon(item.kind),
                          title: item.title,
                          time: _viewModel.timeLabel(item),
                          preview: item.preview,
                          onTap: () => _tapRow(item),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            // Плашка остаётся и над пустой историей: удалили последнюю запись — её ещё можно вернуть.
            Positioned(
              top: padding.top + 75,
              left: 16,
              right: 16,
              child: Center(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: _viewModel.canUndo
                      ? GlassToast.info(message: 'Conversation deleted', action: 'Undo', onAction: _undo)
                      : const SizedBox.shrink(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Пока у строки открыто удаление, нажатие на любую строку только закрывает его.
  void _tapRow(HistoryItem item) {
    if (_openRowId != null) {
      setState(() => _openRowId = null);
      return;
    }
    _viewModel.open(item);
  }

  Future<void> _confirmDelete(HistoryItem item) async {
    // Как в макете: под вопросом строка уже стоит на месте.
    setState(() => _openRowId = null);
    final isConfirmed = await AppDialog.show(
      context,
      icon: AppIcons.trash,
      title: 'Delete this conversation?',
      message: 'It will be removed from your history. This can’t be undone.',
      confirmTitle: 'Continue',
      cancelTitle: 'Cancel',
      isDestructive: true,
    );
    if (!isConfirmed || !mounted) return;
    await _viewModel.delete(item);
    _undoTimer?.cancel();
    _undoTimer = Timer(const Duration(seconds: 3), _viewModel.forgetDeleted);
  }

  void _undo() {
    _undoTimer?.cancel();
    _viewModel.undo();
  }

  static String _icon(HistoryKind kind) => switch (kind) {
    HistoryKind.analysis => AppImages.chat3d,
    HistoryKind.coachConversation => AppImages.question3d,
    HistoryKind.openingLine => AppImages.quotes3d,
  };

  Future<void> _handle(HistoryAction action) async {
    // Клавиатура поиска не должна остаться над открытой записью.
    FocusManager.instance.primaryFocus?.unfocus();
    final navigator = Navigator.of(context);
    switch (action) {
      case OpenBreakdown(:final breakdown):
        await navigator.push(ChatBreakdownScreen.route(breakdown));
      case OpenConversation(:final conversation):
        await Navigator.of(context, rootNavigator: true).push(DatingAdviceScreen.route(conversation: conversation));
      case OpenOpeningLines(:final session):
        await navigator.push(OpeningLineScreen.route(session: session));
      case AnalyzeScreenshot(:final screenshot):
        // Разбор открывается во вкладке, пока сканирование ещё закрывает всё сверху, — и проявляется под ним.
        final outcome = await Navigator.of(context, rootNavigator: true).push(
          AnalyzingScreen.route<ChatBreakdown>(
            screenshot: screenshot,
            task: () => _viewModel.analyze(screenshot),
            onFinished: (breakdown) {
              _viewModel.keep(breakdown);
              navigator.push(ChatBreakdownScreen.route(breakdown, isAnimated: false));
            },
          ),
        );
        if (outcome == AnalyzingOutcome.limitReached && mounted) {
          _viewModel.didReachLimit();
          await _openPlus();
        }
      case OpenPlus():
        await _openPlus();
    }
  }

  Future<void> _openPlus() async {
    if (await PlusSheet.present(context)) _viewModel.didSubscribe();
  }
}
