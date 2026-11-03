import 'package:dating_assistant/service/session/session_manager.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('dating_assistant/otter_scale');
  final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  final calls = <MethodCall>[];

  setUp(() {
    calls.clear();
    messenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      return switch (call.method) {
        'get_user_ids' => {'anonymous': 'anonymous-1'},
        'has_active_subscription' => true,
        _ => null,
      };
    });
  });

  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  test('start initializes the SDK and reads the user ids', () async {
    final sessionManager = SessionManager(host: 'https://otter.test', apiKey: 'key');

    await sessionManager.start();

    expect(calls.first.method, 'initialize');
    expect(calls.first.arguments, {'host': 'https://otter.test', 'api_key': 'key'});
    expect(sessionManager.anonymousId, 'anonymous-1');
    expect(sessionManager.internalId, isNull);
    expect(await sessionManager.hasActiveSubscriptions(), isTrue);
  });

  test('without an API key the SDK stays off', () async {
    final sessionManager = SessionManager(host: 'https://otter.test', apiKey: '');

    await sessionManager.start();

    expect(calls, isEmpty);
    expect(sessionManager.anonymousId, isNull);
    expect(await sessionManager.hasActiveSubscriptions(), isFalse);
  });

  test('a failing SDK does not break the app start', () async {
    messenger.setMockMethodCallHandler(channel, (call) async => throw PlatformException(code: 'initialization_failed'));
    final sessionManager = SessionManager(host: 'https://otter.test', apiKey: 'key');

    await sessionManager.start();

    expect(sessionManager.anonymousId, isNull);
    expect(await sessionManager.hasActiveSubscriptions(), isFalse);
  });
}
