import 'dart:async';
import 'dart:ui' show ImageFilter;

import 'package:dating_assistant/misc/appearance.dart';
import 'package:dating_assistant/misc/assets.dart';
import 'package:dating_assistant/misc/custom_views/pill_chip.dart';
import 'package:dating_assistant/misc/custom_views/primary_button.dart';
import 'package:dating_assistant/misc/custom_views/screen_header.dart';
import 'package:dating_assistant/misc/custom_views/svg_icon.dart';
import 'package:dating_assistant/misc/fonts.dart';
import 'package:dating_assistant/presentation/analysis/chat_breakdown/chat_breakdown_view_model.dart';
import 'package:dating_assistant/presentation/analysis/chat_breakdown/views/breakdown_card.dart';
import 'package:dating_assistant/presentation/analysis/chat_breakdown/views/read_card.dart';
import 'package:dating_assistant/service/analysis/model/chat_breakdown.dart';
import 'package:flutter/material.dart';

/// «Chat breakdown» (аналог ChatBreakdownViewController): что происходит в переписке и что написать дальше.
/// Открывается во вкладке Main поверх главной, таб-бар остаётся.
class ChatBreakdownScreen extends StatefulWidget {
  const ChatBreakdownScreen({super.key, required this.breakdown});

  /// [isAnimated] false — экран появляется под сканированием, которое потом растворяется.
  static Route<void> route(ChatBreakdown breakdown, {bool isAnimated = true}) => isAnimated
      ? MaterialPageRoute(builder: (_) => ChatBreakdownScreen(breakdown: breakdown))
      : _InstantPageRoute(builder: (_) => ChatBreakdownScreen(breakdown: breakdown));

  final ChatBreakdown breakdown;

  @override
  State<ChatBreakdownScreen> createState() => _ChatBreakdownScreenState();
}

class _ChatBreakdownScreenState extends State<ChatBreakdownScreen> {
  late final _viewModel = ChatBreakdownViewModel(widget.breakdown);

  late final StreamSubscription<ChatBreakdownAction> _actions;

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
    final breakdown = _viewModel.breakdown;
    final name = breakdown.partner.name;
    final padding = MediaQuery.paddingOf(context);
    const gap = SizedBox(height: 12);

    return Scaffold(
      body: Stack(
        children: [
          // Сверху — место под шапку, снизу в padding уже входит таб-бар.
          ListView(
            padding: EdgeInsets.fromLTRB(16, padding.top + _TopBar.height + 4, 16, padding.bottom + 16),
            children: [
              ReadCard(read: breakdown.read),
              gap,
              BreakdownRow(
                children: [
                  BreakdownCard(
                    emoji: '💘',
                    title: 'Who’s more interested?',
                    children: [
                      InterestMeter(who: name, interest: breakdown.theirInterest, color: Appearance.accent),
                      InterestMeter(who: 'You', interest: breakdown.yourInterest, color: Appearance.grey),
                      Text('Estimated from the text', style: BreakdownStyles.note),
                    ],
                  ),
                  BreakdownCard(
                    emoji: '🏋️',
                    title: 'Who’s carrying the chat?',
                    children: [
                      ShareBar(who: name, percent: breakdown.theirWordShare, color: Appearance.accent),
                      ShareBar(who: 'You', percent: breakdown.yourWordShare, color: Appearance.grey),
                      Text('Share of the words', style: BreakdownStyles.note),
                    ],
                  ),
                ],
              ),
              if (breakdown.goingWell.isNotEmpty || breakdown.watchOut.isNotEmpty) ...[
                gap,
                BreakdownRow(
                  children: [
                    if (breakdown.goingWell.isNotEmpty)
                      BreakdownCard(
                        emoji: '🙌',
                        title: 'Going well',
                        children: [for (final signal in breakdown.goingWell) SignalItem(signal: signal)],
                      ),
                    if (breakdown.watchOut.isNotEmpty)
                      BreakdownCard(
                        emoji: '👀',
                        title: 'Watch out',
                        children: [for (final signal in breakdown.watchOut) SignalItem(signal: signal)],
                      ),
                  ],
                ),
              ],
              if (breakdown.topics.isNotEmpty) ...[
                gap,
                BreakdownCard(
                  emoji: '💡',
                  title: 'What to talk about',
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final topic in breakdown.topics)
                          PillChip(
                            label: '${topic.emoji} ${topic.title}',
                            isSelected: false,
                            onTap: () => _viewModel.openTopic(topic),
                          ),
                      ],
                    ),
                    Text('From $name’s messages — tap for a line', style: BreakdownStyles.note),
                  ],
                ),
              ],
              gap,
              BreakdownRow(
                children: [
                  BreakdownCard(
                    emoji: '✨',
                    title: 'Texting vibe',
                    children: [
                      VibeRow(who: name, vibe: breakdown.theirVibe),
                      VibeRow(who: 'You', vibe: breakdown.yourVibe),
                    ],
                  ),
                  BreakdownCard(
                    emoji: '🔥',
                    title: 'Where it’s heading',
                    children: [
                      _Heading(heading: breakdown.heading),
                      Text(breakdown.heading.detail, style: BreakdownStyles.value),
                    ],
                  ),
                ],
              ),
              gap,
              BreakdownCard(
                emoji: '🎯',
                title: 'Your next move',
                children: [
                  Text(breakdown.nextMove, style: Fonts.body.copyWith(height: 24 / 16)),
                  PrimaryButton(title: 'Get the next message', onPressed: _viewModel.getNextMessage),
                  Text(
                    'Opens the coach with this chat attached',
                    textAlign: TextAlign.center,
                    style: BreakdownStyles.note,
                  ),
                ],
              ),
            ],
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _TopBar(title: _viewModel.title, onBack: () => Navigator.of(context).maybePop()),
          ),
        ],
      ),
    );
  }

  void _handle(ChatBreakdownAction action) {
    switch (action) {
      // TODO: открыть первую фразу на эту тему — фича Opening line (Figma 190:1787).
      case OpenTopicLine():
      // TODO: открыть коуча с этой перепиской — фича Dating advice (Figma 190:2058).
      case OpenCoach():
        debugPrint('ChatBreakdownScreen: $action is not implemented yet');
    }
  }
}

/// «Warming up ↗»: куда идёт переписка и стрелка тренда.
class _Heading extends StatelessWidget {
  const _Heading({required this.heading});

  final ChatHeading heading;

  @override
  Widget build(BuildContext context) {
    const arrow = SvgIcon(AppIcons.trendUp, size: 18, color: Appearance.accent);
    return Row(
      children: [
        Flexible(
          child: Text(heading.label, style: Fonts.headline.copyWith(fontSize: 18, height: 22.7 / 18)),
        ),
        if (heading.trend != ChatTrend.flat) ...[
          const SizedBox(width: 6),
          heading.trend == ChatTrend.up ? arrow : Transform.flip(flipY: true, child: arrow),
        ],
      ],
    );
  }
}

/// Шапка поверх разбора: затемнение с размытием, «назад» и имя. Кнопку «поделиться» из макета убрали:
/// пока непонятно, чем делиться.
class _TopBar extends StatelessWidget {
  const _TopBar({required this.title, required this.onBack});

  /// Без отступа сверху: 11 + шапка 48 + 12.
  static const height = 71.0;

  final String title;

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Размытие кончается до нижних 12: иначе оно подтягивает в шапку цвет карточки под ней,
        // и по краю видна светлая полоса. Ниже остаётся только затемнение.
        Positioned(
          left: 0,
          right: 0,
          top: 0,
          bottom: 12,
          child: ClipRect(
            child: BackdropFilter(filter: _blur, child: const SizedBox.expand()),
          ),
        ),
        DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xE6000000), Color(0xB8000000), Color(0x00000000)],
              stops: [0, 0.7, 1],
            ),
          ),
          child: Padding(
            padding: EdgeInsets.fromLTRB(16, MediaQuery.paddingOf(context).top + 11, 16, 12),
            child: ScreenHeader(title: title, onBack: onBack),
          ),
        ),
      ],
    );
  }

  static final _blur = ImageFilter.blur(sigmaX: 8, sigmaY: 8);
}

/// Появляется без анимации, а уходит как обычный экран — со свайпом назад на iOS.
class _InstantPageRoute<T> extends MaterialPageRoute<T> {
  _InstantPageRoute({required super.builder});

  @override
  Duration get transitionDuration => Duration.zero;

  @override
  Duration get reverseTransitionDuration => super.transitionDuration;
}
