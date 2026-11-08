import 'dart:async';

import 'package:dating_assistant/misc/appearance.dart';
import 'package:dating_assistant/misc/assets.dart';
import 'package:dating_assistant/misc/components/instant_page_route.dart';
import 'package:dating_assistant/misc/custom_views/blurred_top_bar.dart';
import 'package:dating_assistant/misc/custom_views/pill_chip.dart';
import 'package:dating_assistant/misc/custom_views/primary_button.dart';
import 'package:dating_assistant/misc/custom_views/svg_icon.dart';
import 'package:dating_assistant/misc/fonts.dart';
import 'package:dating_assistant/presentation/analysis/chat_breakdown/chat_breakdown_view_model.dart';
import 'package:dating_assistant/presentation/analysis/chat_breakdown/views/breakdown_card.dart';
import 'package:dating_assistant/presentation/analysis/chat_breakdown/views/read_card.dart';
import 'package:dating_assistant/presentation/dating_advice/dating_advice/dating_advice_screen.dart';
import 'package:dating_assistant/presentation/opening_line/opening_line/opening_line_screen.dart';
import 'package:dating_assistant/service/analysis/model/chat_breakdown.dart';
import 'package:dating_assistant/service/opening_line/model/opening_line.dart';
import 'package:flutter/material.dart';

/// «Chat breakdown» (аналог ChatBreakdownViewController): что происходит в переписке и что написать дальше.
/// Открывается во вкладке Main поверх главной, таб-бар остаётся.
class ChatBreakdownScreen extends StatefulWidget {
  const ChatBreakdownScreen({super.key, required this.breakdown});

  /// [isAnimated] false — экран появляется под сканированием, которое потом растворяется.
  static Route<void> route(ChatBreakdown breakdown, {bool isAnimated = true}) => isAnimated
      ? MaterialPageRoute(builder: (_) => ChatBreakdownScreen(breakdown: breakdown))
      : InstantPageRoute(builder: (_) => ChatBreakdownScreen(breakdown: breakdown));

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
            padding: EdgeInsets.fromLTRB(16, padding.top + BlurredTopBar.height + 4, 16, padding.bottom + 16),
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
          // Кнопку «поделиться» из макета убрали: пока непонятно, чем делиться.
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: BlurredTopBar(title: _viewModel.title, onBack: () => Navigator.of(context).maybePop()),
          ),
        ],
      ),
    );
  }

  void _handle(ChatBreakdownAction action) {
    switch (action) {
      case OpenTopicLine(:final topic):
        // Первая фраза на тему из переписки — тот же экран, что у Opening line.
        final partner = _viewModel.breakdown.partner;
        Navigator.of(context).push(
          OpeningLineScreen.route(
            match: MatchDetails(name: partner.name, age: partner.age, interests: topic.title),
          ),
        );
      case OpenCoach():
        // Коуч с этой перепиской закрывает таб-бар: внизу у него поле ввода.
        Navigator.of(context, rootNavigator: true).push(DatingAdviceScreen.route(breakdown: _viewModel.breakdown));
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
