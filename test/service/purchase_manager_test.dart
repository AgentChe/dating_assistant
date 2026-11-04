import 'package:dating_assistant/service/purchase/model/purchase_error.dart';
import 'package:dating_assistant/service/purchase/model/purchase_result.dart';
import 'package:dating_assistant/service/purchase/purchase_manager.dart';
import 'package:dating_assistant/service/session/session_manager.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase_platform_interface/in_app_purchase_platform_interface.dart';

import '../fakes/fake_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('dating_assistant/otter_scale');
  final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  late List<MethodCall> otterScaleCalls;
  late FakeStore store;

  PurchaseManager makeManager({String apiKey = 'key'}) => PurchaseManager(
    sessionManager: SessionManager(host: 'https://otter.test', apiKey: apiKey),
  )..start();

  setUp(() {
    otterScaleCalls = [];
    store = FakeStore(products: [fakeProduct('yearly', 59.99), fakeProduct('weekly', 7.99)]);
    InAppPurchasePlatform.instance = store;
    messenger.setMockMethodCallHandler(channel, (call) async {
      otterScaleCalls.add(call);
      return switch (call.method) {
        'has_active_subscription' => true,
        'get_user_ids' => {'anonymous': 'anonymous-1', 'internal': 'internal-1'},
        _ => null,
      };
    });
  });

  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  test('obtainProducts keeps the requested order and skips unknown ids', () async {
    final products = await makeManager().obtainProducts(['weekly', 'missing', 'yearly']);

    expect(products.map((product) => product.id), ['weekly', 'yearly']);
  });

  test('obtainProducts fails when the store is unavailable', () async {
    InAppPurchasePlatform.instance = FakeStore(isStoreAvailable: false);

    await expectLater(
      makeManager().obtainProducts(['yearly']),
      throwsA(isA<PurchaseError>().having((error) => error.code, 'code', PurchaseErrorCode.storeUnavailable)),
    );
  });

  test('Android: the receipt goes to OtterScale, then the purchase is completed', () async {
    final manager = makeManager();
    final yearly = (await manager.obtainProducts(['yearly'])).single;

    expect(await manager.buy(yearly), PurchaseResult.subscribed);

    final save = otterScaleCalls.singleWhere((call) => call.method == 'save_purchase');
    expect(save.arguments, {
      'purchase_data': '{"orderId":"order-yearly"}',
      'product_id': 'yearly',
      'price': 59.99,
      'currency': 'USD',
    });
    expect(store.completedPurchases.single.productID, 'yearly');
  });

  test('iOS: waits until OtterScale validates the receipt', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    final manager = makeManager();
    final yearly = (await manager.obtainProducts(['yearly'])).single;

    final result = manager.buy(yearly);
    await pumpEventQueue();
    expect(otterScaleCalls.where((call) => call.method == 'save_purchase'), isEmpty);
    expect(store.completedPurchases, hasLength(1));

    await messenger.handlePlatformMessage(
      channel.name,
      channel.codec.encodeMethodCall(const MethodCall('receipt_validated')),
      (_) {},
    );
    expect(await result, PurchaseResult.subscribed);
  });

  test('a cancelled payment is not an error', () async {
    store.nextPurchaseStatus = PurchaseStatus.canceled;
    final manager = makeManager();
    final yearly = (await manager.obtainProducts(['yearly'])).single;

    expect(await manager.buy(yearly), PurchaseResult.cancelled);
  });

  test('a failed payment throws', () async {
    store.nextPurchaseStatus = PurchaseStatus.error;
    final manager = makeManager();
    final yearly = (await manager.obtainProducts(['yearly'])).single;

    await expectLater(
      manager.buy(yearly),
      throwsA(isA<PurchaseError>().having((error) => error.code, 'code', PurchaseErrorCode.paymentFailed)),
    );
  });

  test('restore with nothing to restore', () async {
    expect(await makeManager().restore(), PurchaseResult.notSubscribed);
  });

  test('restored purchases are validated again', () async {
    store.restoredPurchases = [FakeStore.purchase('yearly', PurchaseStatus.restored)];

    expect(await makeManager().restore(), PurchaseResult.subscribed);
    expect(otterScaleCalls.where((call) => call.method == 'save_purchase'), hasLength(1));
  });

  test('without the OtterScale key the purchase is only completed', () async {
    final manager = makeManager(apiKey: '');
    final yearly = (await manager.obtainProducts(['yearly'])).single;

    expect(await manager.buy(yearly), PurchaseResult.notSubscribed);
    expect(otterScaleCalls, isEmpty);
    expect(store.completedPurchases, hasLength(1));
  });
}
