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

  test('the active subscription is the valid one that ends last', () async {
    messenger.setMockMethodCallHandler(channel, (call) async {
      if (call.method != 'get_subscriptions') return null;
      return [
        {
          'product_id': 'old',
          'valid': false,
          'expiration': '2026-08-01T10:00:00Z',
          'status': 'paid',
          'renewing': false,
        },
        {
          'product_id': 'weekly',
          'valid': true,
          'expiration': '2026-09-23T10:00:00Z',
          'status': 'trial',
          'renewing': true,
        },
        {
          'product_id': 'yearly',
          'valid': true,
          'expiration': '2026-09-20T10:00:00Z',
          'status': 'paid',
          'renewing': false,
        },
      ];
    });
    final sessionManager = SessionManager(host: 'https://otter.test', apiKey: 'key');

    final subscription = (await sessionManager.activeSubscription())!;

    expect(subscription.productId, 'weekly');
    expect(subscription.expiresAt, DateTime.utc(2026, 9, 23, 10).toLocal());
    expect(subscription.isTrial, isTrue);
    expect(subscription.willRenew, isTrue);
  });

  test('without a valid subscription there is no active one', () async {
    messenger.setMockMethodCallHandler(channel, (call) async {
      if (call.method != 'get_subscriptions') return null;
      return [
        {'product_id': 'weekly', 'valid': false, 'expiration': 'not a date', 'status': 'refund', 'renewing': false},
      ];
    });

    expect(await SessionManager(host: 'https://otter.test', apiKey: 'key').activeSubscription(), isNull);
    expect(await SessionManager(host: 'https://otter.test', apiKey: '').activeSubscription(), isNull);
  });

  test('a failing SDK does not break the app start', () async {
    messenger.setMockMethodCallHandler(channel, (call) async => throw PlatformException(code: 'initialization_failed'));
    final sessionManager = SessionManager(host: 'https://otter.test', apiKey: 'key');

    await sessionManager.start();

    expect(sessionManager.anonymousId, isNull);
    expect(await sessionManager.hasActiveSubscriptions(), isFalse);
  });
}
