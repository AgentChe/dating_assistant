import 'package:dating_assistant/service/opening_line/model/opening_line.dart';
import 'package:dating_assistant/service/profile/model/spice_level.dart';
import 'package:dating_assistant/service/usage/usage_manager.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_analysis.dart';
import '../fakes/fake_opening_line.dart';

void main() {
  late MockOpeningLines mock;
  late int generationsUsed;

  setUp(() async {
    mock = await mockOpeningLines();
    generationsUsed = 0;
    mock.usageMediator.changes.listen((_) => generationsUsed++);
  });

  test('a profile screenshot gives a line and what the server read in the bio', () async {
    final line = await mock.manager.generate(spice: SpiceLevel.warm, profileScreenshot: fakeScreenshot);
    await pumpEventQueue();

    expect(line.text, 'fair. what would have to happen down here for you to come back?');
    expect(line.match?.name, 'Nika');
    expect(line.match?.age, 28);
    expect(line.match?.interests, 'Into mountains, not into small talk');
    expect(generationsUsed, 1);
  });

  test('typed details make the line personal', () async {
    final line = await mock.manager.generate(
      spice: SpiceLevel.playful,
      match: const MatchDetails(name: 'Sam', interests: 'Climbing, bad puns'),
    );

    expect(line.text, contains('climbing'));
    expect(line.match, isNull);
  });

  test('the next line does not repeat the previous ones', () async {
    final first = await mock.manager.generate(spice: SpiceLevel.bold);
    final second = await mock.manager.generate(spice: SpiceLevel.bold, previousLines: [first.text]);

    expect(second.text, isNot(first.text));
  });

  test('without details the line still comes, in the chosen spice', () async {
    final soft = await mock.manager.generate(spice: SpiceLevel.soft);
    final spicy = await mock.manager.generate(spice: SpiceLevel.spicy);

    expect(soft.text, isNotEmpty);
    expect(spicy.text, isNot(soft.text));
  });

  test('the fourth free generation in a week asks for Cue Plus', () async {
    for (var index = 0; index < 3; index++) {
      await mock.manager.generate(spice: SpiceLevel.warm);
    }

    final error = await mock.manager
        .generate(spice: SpiceLevel.warm)
        .then<Object?>((_) => null, onError: (Object error) => error);
    await pumpEventQueue();

    expect(UsageManager.isGenerationLimit(error!), isTrue);
    expect(generationsUsed, 3);
  });
}
