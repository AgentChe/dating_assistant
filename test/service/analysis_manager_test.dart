import 'dart:typed_data';

import 'package:dating_assistant/service/analysis/analysis_manager.dart';
import 'package:dating_assistant/service/analysis/model/chat_breakdown.dart';
import 'package:dating_assistant/service/usage/usage_manager.dart';
import 'package:dating_assistant/service/usage/usage_mediator.dart';
import 'package:dating_assistant/transport/network_error.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_analysis.dart';

void main() {
  late UsageMediator usageMediator;
  late AnalysisManager analysisManager;
  late int generationsUsed;

  setUp(() async {
    usageMediator = UsageMediator();
    generationsUsed = 0;
    usageMediator.changes.listen((_) => generationsUsed++);
    analysisManager = await mockAnalysisManager(usageMediator: usageMediator);
  });

  test('a screenshot turns into a chat breakdown', () async {
    final breakdown = await analysisManager.analyzeScreenshot(fakeScreenshot);
    await pumpEventQueue();

    expect(breakdown.partner, (name: 'Nika', age: 28));
    expect(breakdown.read.verdict, 'Nika is into this');
    expect(breakdown.theirInterest, (level: 4, label: 'Warm'));
    expect(breakdown.yourInterest, (level: 3, label: 'Mixed'));
    expect((breakdown.theirWordShare, breakdown.yourWordShare), (70, 30));
    expect(breakdown.goingWell.first, (title: 'Asked about you', proof: '“is that tent real…”'));
    expect(breakdown.watchOut, hasLength(2));
    expect([for (final topic in breakdown.topics) topic.title], ['Mountains', 'The tent', 'Getaways']);
    expect(breakdown.theirVibe.label, 'Playful');
    expect(breakdown.heading.trend, ChatTrend.up);
    expect(breakdown.nextMove, startsWith('Ask about the mountains'));
    expect(generationsUsed, 1);
  });

  test('after three free generations the server asks for Cue Plus', () async {
    for (var index = 0; index < 3; index++) {
      await analysisManager.analyzeScreenshot(fakeScreenshot);
    }

    final error = await analysisManager
        .analyzeScreenshot(fakeScreenshot)
        .then<Object?>((_) => null, onError: (Object error) => error);
    await pumpEventQueue();

    expect(error, isA<NetworkError>().having((error) => error.statusCode, 'status', 402));
    expect(UsageManager.isGenerationLimit(error!), isTrue);
    expect(generationsUsed, 3);
  });

  test('an empty screenshot is rejected without spending a generation', () async {
    await expectLater(
      analysisManager.analyzeScreenshot(Uint8List(0)),
      throwsA(isA<NetworkError>().having((error) => error.statusCode, 'status', 400)),
    );
    expect(generationsUsed, 0);
  });
}
