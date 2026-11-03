import 'package:dating_assistant/misc/app.dart';
import 'package:dating_assistant/misc/injector.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  testWidgets('onboarding on mocks creates a profile that the profile screen shows', (tester) async {
    SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
    await Injector.configure();

    await tester.pumpWidget(const App());
    await tester.pumpAndSettle();
    expect(find.text('About you'), findsOneWidget);

    await tester.tap(find.text('Female'));
    await tester.tap(find.text('Serious relationship'));
    await tester.pump();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(find.text('Main feature goes here'), findsOneWidget);

    await tester.tap(find.byTooltip('Profile'));
    await tester.pumpAndSettle();
    expect(find.text('Female'), findsOneWidget);
    expect(find.text('Serious relationship'), findsOneWidget);
  });
}
