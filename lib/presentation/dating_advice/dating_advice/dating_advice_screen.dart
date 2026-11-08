import 'dart:async';
import 'dart:math' as math;

import 'package:dating_assistant/misc/components/measure_size.dart';
import 'package:dating_assistant/misc/custom_views/blurred_top_bar.dart';
import 'package:dating_assistant/misc/custom_views/copied_toast.dart';
import 'package:dating_assistant/misc/custom_views/try_again_sheet.dart';
import 'package:dating_assistant/presentation/dating_advice/dating_advice/dating_advice_view_model.dart';
import 'package:dating_assistant/presentation/dating_advice/dating_advice/views/chat_bubble.dart';
import 'package:dating_assistant/presentation/dating_advice/dating_advice/views/chat_context_card.dart';
import 'package:dating_assistant/presentation/dating_advice/dating_advice/views/composer.dart';
import 'package:dating_assistant/presentation/dating_advice/dating_advice/views/quick_replies.dart';
import 'package:dating_assistant/presentation/dating_advice/dating_advice/views/suggestion_card.dart';
import 'package:dating_assistant/presentation/dating_advice/dating_advice/views/tone_sheet.dart';
import 'package:dating_assistant/presentation/dating_advice/dating_advice/views/typing_bubble.dart';
import 'package:dating_assistant/presentation/splash/plus_sheet/plus_sheet.dart';
import 'package:dating_assistant/service/analysis/model/chat_breakdown.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// «Dating advice» (аналог DatingAdviceViewController): чат с коучем. Открывается поверх таб-бара —
/// внизу у него поле ввода, а над ним быстрые ответы.
class DatingAdviceScreen extends StatefulWidget {
  const DatingAdviceScreen({super.key, this.breakdown, this.viewModel});

  /// [breakdown] — разбор, из которого открыли коуча («Get the next message»): переписка уже приложена.
  static Route<void> route({ChatBreakdown? breakdown}) =>
      MaterialPageRoute(builder: (_) => DatingAdviceScreen(breakdown: breakdown));

  final ChatBreakdown? breakdown;

  /// Для тестов; в приложении экран создаёт ViewModel сам.
  final DatingAdviceViewModel? viewModel;

  @override
  State<DatingAdviceScreen> createState() => _DatingAdviceScreenState();
}

class _DatingAdviceScreenState extends State<DatingAdviceScreen> {
  late final _viewModel = widget.viewModel ?? DatingAdviceViewModel(breakdown: widget.breakdown);

  late final StreamSubscription<DatingAdviceAction> _actions;

  final _draft = TextEditingController();

  final _scroll = ScrollController();

  /// Высота шапки и панели с полем ввода: лента прокручивается под ними. До первого замера — по макету.
  double? _topBarHeight;

  double? _bottomBarHeight;

  /// Последнее, что видели в конце ленты, — чтобы показать новое сообщение, даже если листали вверх.
  ({int entries, bool isReplying})? _latest;

  /// Только что скопированное сообщение — для галочки и плашки.
  String? _copiedText;

  Timer? _copiedTimer;

  @override
  void initState() {
    super.initState();
    _actions = _viewModel.actions.listen(_handle);
    _viewModel.tryAgain = (error) => TryAgainSheet.show(context, error);
    _viewModel.addListener(_revealLatest);
    _viewModel.start();
  }

  @override
  void dispose() {
    _copiedTimer?.cancel();
    _actions.cancel();
    _viewModel.removeListener(_revealLatest);
    _viewModel.dispose();
    _draft.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final padding = MediaQuery.paddingOf(context);
    return Scaffold(
      body: ListenableBuilder(
        listenable: _viewModel,
        builder: (context, _) {
          final card = _viewModel.chatCard;
          final quickReplies = _viewModel.quickReplies;
          final topBarHeight = _topBarHeight ?? padding.top + BlurredTopBar.height + (card == null ? 0 : 101);
          final bottomBarHeight =
              _bottomBarHeight ?? (quickReplies.isEmpty ? 0 : 48) + 104 + math.max(padding.bottom + 2, 12);

          return Stack(
            children: [
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => FocusScope.of(context).unfocus(),
                  // Лента перевёрнута и держится за последнее сообщение, а пока сообщений мало — прижата к шапке.
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: ListView(
                      controller: _scroll,
                      reverse: true,
                      shrinkWrap: true,
                      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                      padding: EdgeInsets.fromLTRB(16, topBarHeight + 4, 16, bottomBarHeight + 16),
                      children: _feed(),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: MeasureSize(
                  onChange: (size) => setState(() => _topBarHeight = size.height),
                  child: BlurredTopBar(
                    title: 'Dating advice',
                    onBack: () => Navigator.of(context).maybePop(),
                    bottom: card == null ? null : ChatContextCard(title: card.title, verdict: card.verdict),
                  ),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: MeasureSize(
                  onChange: (size) => setState(() => _bottomBarHeight = size.height),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (quickReplies.isNotEmpty) ...[
                        QuickReplies(replies: quickReplies, onTap: _viewModel.sendQuickReply),
                        const SizedBox(height: 8),
                      ],
                      Composer(
                        controller: _draft,
                        tone: _viewModel.tone,
                        isEnabled: !_viewModel.isLimitReached,
                        canSend: _viewModel.canSend,
                        onChanged: _viewModel.changeDraft,
                        onSend: _viewModel.sendDraft,
                        onAttach: _viewModel.attachScreenshot,
                        onTone: _viewModel.openTonePicker,
                        onDisabledTap: _viewModel.openPlus,
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                top: padding.top + 75,
                left: 16,
                right: 16,
                child: Center(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: _copiedText != null ? const CopiedToast() : const SizedBox.shrink(),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Сообщения снизу вверх — лента перевёрнута. Между сообщениями 16, совет коуча и его карточка — вплотную, через 8.
  List<Widget> _feed() {
    final items = <(Key, Widget)>[
      for (final entry in _viewModel.entries)
        switch (entry) {
          CoachEntry(:final text, :final suggestion) => (
            ValueKey(entry.id),
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ChatBubble.coach(text: text),
                if (suggestion != null) ...[
                  const SizedBox(height: 8),
                  SuggestionCard(
                    suggestion: suggestion,
                    isCopied: suggestion.text == _copiedText,
                    onCopy: () => _copy(suggestion.text),
                  ),
                ],
              ],
            ),
          ),
          UserEntry(:final text) => (ValueKey(entry.id), ChatBubble.user(text: text)),
        },
      if (_viewModel.isReplying) (const ValueKey('typing'), const TypingBubble()),
    ];
    return [
      for (final (index, (key, child)) in items.indexed.toList().reversed)
        _Appear(
          key: key,
          child: Padding(
            padding: EdgeInsets.only(top: index == 0 ? 0 : 16),
            child: child,
          ),
        ),
    ];
  }

  /// Новое сообщение или «печатает» — прокручиваем к концу ленты, даже если пользователь листал вверх.
  void _revealLatest() {
    final latest = (entries: _viewModel.entries.length, isReplying: _viewModel.isReplying);
    if (latest == _latest) return;
    _latest = latest;
    if (_scroll.hasClients && _scroll.offset > 0) {
      _scroll.animateTo(0, duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
    }
  }

  void _copy(String text) {
    Clipboard.setData(ClipboardData(text: text));
    HapticFeedback.selectionClick();
    setState(() => _copiedText = text);
    _copiedTimer?.cancel();
    _copiedTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copiedText = null);
    });
  }

  Future<void> _handle(DatingAdviceAction action) async {
    switch (action) {
      case OpenPlus():
        FocusScope.of(context).unfocus();
        if (await PlusSheet.present(context)) _viewModel.didSubscribe();
      case PickTone(:final tone):
        final selected = await ToneSheet.show(context, selected: tone);
        if (selected != null) _viewModel.selectTone(selected);
      case ReplaceDraft(:final text):
        _draft.value = TextEditingValue(
          text: text,
          selection: TextSelection.collapsed(offset: text.length),
        );
    }
  }
}

/// Новое сообщение проявляется и чуть всплывает. Уже показанные не мигают: их узнают по ключу.
/// VoiceOver и TalkBack видят сообщение сразу, не дожидаясь анимации.
class _Appear extends StatelessWidget {
  const _Appear({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
      builder: (context, value, child) => Opacity(
        opacity: value,
        alwaysIncludeSemantics: true,
        child: Transform.translate(offset: Offset(0, 8 * (1 - value)), child: child),
      ),
      child: child,
    );
  }
}
