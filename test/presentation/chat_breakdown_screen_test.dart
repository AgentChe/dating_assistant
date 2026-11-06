import 'package:dating_assistant/misc/custom_views/screen_header.dart';
import 'package:dating_assistant/presentation/analysis/chat_breakdown/chat_breakdown_screen.dart';
import 'package:dating_assistant/service/analysis/model/chat_breakdown.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_analysis.dart';

void main() {
  late ChatBreakdown breakdown;

  setUpAll(() async => breakdown = await exampleBreakdown());

  Future<void> open(WidgetTester tester, ChatBreakdown breakdown) async {
    tester.view
      ..physicalSize = const Size(1284, 2778)
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(home: ChatBreakdownScreen(breakdown: breakdown)));
    await tester.pumpAndSettle();
  }

  testWidgets('shows the whole breakdown down to the next move', (tester) async {
    await open(tester, breakdown);

    expect(find.text('Nika, 28'), findsOneWidget);
    expect(find.text('Nika is into this'), findsOneWidget);
    expect(find.text('Warm'), findsOneWidget);
    expect(find.text('Mixed'), findsOneWidget);
    expect(find.text('70%'), findsOneWidget);
    expect(find.text('Asked about you'), findsOneWidget);
    expect(find.text('Nika leads for now'), findsOneWidget);

    await tester.scrollUntilVisible(find.text('Get the next message'), 300);
    expect(find.text('🏔️ Mountains'), findsOneWidget);
    expect(find.text('From Nika’s messages — tap for a line'), findsOneWidget);
    expect(find.text('😜 Playful'), findsOneWidget);
    expect(find.text('Warming up'), findsOneWidget);
    expect(find.text('Ask about the mountains. Give Nika a reason to keep talking.'), findsOneWidget);
  });

  testWidgets('without an age the title is just the name, and a lone card takes the full width', (tester) async {
    await open(
      tester,
      ChatBreakdown(
        id: 'analysis-2',
        partner: (name: 'Sam', age: null),
        read: breakdown.read,
        theirInterest: breakdown.theirInterest,
        yourInterest: breakdown.yourInterest,
        theirWordShare: 50,
        yourWordShare: 50,
        goingWell: const [],
        watchOut: breakdown.watchOut,
        topics: breakdown.topics,
        theirVibe: breakdown.theirVibe,
        yourVibe: breakdown.yourVibe,
        heading: (label: 'Cooling off', trend: ChatTrend.down, detail: 'Replies are getting shorter.'),
        nextMove: breakdown.nextMove,
      ),
    );

    expect(find.descendant(of: find.byType(ScreenHeader), matching: find.text('Sam')), findsOneWidget);
    expect(find.text('Going well'), findsNothing);
    final watchOut = find.ancestor(of: find.text('Watch out'), matching: find.byType(Container)).first;
    expect(tester.getSize(watchOut).width, 396);
  });
}
